
$serverDest = "BRSPDSRV200FS03.OMNIACCESS.NET"

Copy-Item C:\zabbix\ -Destination \\$serverDest\c$\  -Recurse -Verbose
Invoke-Command -ScriptBlock {c:\zabbix\Install-zabbix-Agent.bat} -ComputerName $serverDest
Start-Sleep 3
Invoke-Command -ScriptBlock {Get-Service "zabbix agent" | start-service} -ComputerName $serverDest
Invoke-Command -ScriptBlock {Get-Service "zabbix agent" | restart-service} -ComputerName $serverDest
Start-Sleep 5
Invoke-Command -ScriptBlock {Get-Service "zabbix agent"} -ComputerName $serverDest
Invoke-Command -ScriptBlock {New-NetFirewallRule -DisplayName "Zabbix-Agent" -Direction Inbound -Action Allow -LocalPort 10050 -Protocol TCP} -ComputerName $serverDest

