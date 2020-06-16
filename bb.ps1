## Bamboo Configuration Script - Josh Allan

$wd = "C:\Bamboo"
$bbagent = #TODO
$outfile = "C:\Bamboo\agent.jar"
$start_time = Get-Date
$path_dll = "c:\bamboo\lib\wrapper.dll"
$bbcap = "Z:\Applications\Scripts\bamboo-capabilities.properties"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$sleep = start-sleep -seconds 20
$svc = Get-WmiObject win32_service -computername "localhost" -filter "name='bamboo-remote-agent'" -Credential $cred 
$serviceAccount = #TODO
$cred = Get-Credential $serviceAccount

write-host `r`n"Checking to see if directory exists, otherwise lets create it" 

if(!(test-path $wd)){
    New-Item -ItemType Directory -Force -Path $wd
    write-host `r`n"Creating" $wd
} else {
    write-host `r`n$wd "Exists"
}

write-host `r`n"Changing Working Directory to $wd"
set-location $wd

write-host `r`n"Grabbing the installer for the remote agent"

(New-Object System.Net.WebClient).DownloadFile($bbagent, $outfile)
write-host `r`n"Completed in $((Get-Date).Subtract($start_time).Seconds) seconds"

write-host `r`n"Starting Java Executable, killing it after all files are present"
Start-Process "cmd" -ArgumentList "/c java -jar -Dbamboo.home=c:\bamboo agent.jar #ADD-IN AGENT SERVER"

$i = 0 #Check counter to time out script if Java dependencies aren't on the path correctly 
while($i -lt 5){
    if((test-path -Path $path_dll) -eq $true){
        Write-Host "All the files are in the right place, lets kill the wrapper"
        get-process "wrapper" | Stop-Process
        break
    } else {
        write-host "All the files aren't there yet - waiting.."
        $sleep
        $i++
    } if($i -eq 5){
        throw "Timed out" #Throw terminating error so loop will break instead of run endlessly
    }
}

write-host `r`n"Sleeping the script for twenty seconds to allow the wrapper to stop"
$sleep

write-host `r`n"Adding capabilities"
Copy-Item -Path $bbcap -Destination "C:\Bamboo\bin\bamboo-capabilities.properties" -Force

write-host `r`n"Install the Agent as a NT Service"
start-process "cmd" -ArgumentList "/c c:\bamboo\bin\InstallBambooAgent-NT.bat"

$sleep

write-host `r`n"Enabling Remote Desktop without NLA"

if(!(Test-Path $regPath)){ 
    New-Item -Path $regPath -Force | Out-Null 
    New-ItemProperty -Path $regPath -Name "UserAuthentication"  -Value "00000000" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "SecurityLayer" -Value "00000000" -PropertyType DWORD -Force | Out-Null 
}

write-host `r`n"Reconfiguring the service account"
$stopstatus = $svc.stopservice()
if($stopstatus.returnvalue -eq "0"){
    write-host "Service stopped successfully"
}

$changestatus = $svc.change($null,$null,$null,$null,$null,$null,$cred,$cred,$null,$null,$null)

if($changestatus.returnvalue -eq "0"){
    write-host "Credentials updated successfully"
} elseif($changestatus.returnvalue -eq "1"){
    write-host "Credentials failed to update"
}

$svc.startservice()

if($changestatus.returnvalue -eq "0"){
    write-host "Service started successfully"
}

Write-Host `r`n"Killing the Firewall Policies to enable PS Remoting"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Enable-PSRemoting

Write-Host `r`n "Deleting the jar"
Remove-Item $outfile -Force