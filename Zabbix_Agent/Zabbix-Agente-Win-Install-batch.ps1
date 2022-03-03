# Base em um aquivo csv com
# Ajustar arquivo para o arquivo onde esta o hostname.
$serverDest = import-csv "C:\Temp\SLZ-SRV.csv" |

ForEach-Object {
    $CompuName = $_.srv
    Write-Host $CompuName -ForegroundColor Blue
    
    try{Connect-WSMan -computername $CompuName -ErrorAction SilentlyContinue} # -- Testa conexao powershell com destino.
    catch{ $FailCount = 1}

    $TestZabbixPath = Test-Path -Path \\$CompuName\c$\zabbix   # -- Testa se a pasta Zabbix existe no destino e copia caso nao exista.
    if ($TestZabbixPath -eq $false) { 
    
        $From = "\\BRSPDSRV200FS01.OMNIACCESS.NET\BackOffice\TI\Temp\zabbix\"
        $To = "\\$CompuName\c$\zabbix"
        Copy-Item  $From -Destination $To -PassThru -Recurse
    }
    
    if ($FailCount -ne 1) {
                
                Invoke-Command -ComputerName $CompuName -ScriptBlock { 
                $svc = Get-Service -Name 'Zabbix Agent' -ErrorAction SilentlyContinue
                $GHostname = hostname 
                                     
        if ($svc -eq $null){
                c:\zabbix\Install-zabbix-Agent.bat
                Start-Sleep 3
                Get-Service "zabbix agent" | start-service
                Start-Sleep 5
                Get-Service "zabbix agent" | restart-service
                Start-Sleep 5
                Get-Service "zabbix agent"
                New-NetFirewallRule -DisplayName "Zabbix-Agent" -Direction Inbound -Action Allow -LocalPort 10050 -Protocol TCP
            }
        else { write-host ""$GHostname" tem zabbix agent." -ForegroundColor Yellow }
        }

    }
   
    else { write-host ""$CompuName" powershell nao conecta." -ForegroundColor Red }

    $FailCount = $null
}
