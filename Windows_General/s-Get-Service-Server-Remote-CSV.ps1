
import-csv ".\s-Get-Service-Server-Remote-CSV.csv" |

 ForEach-Object {
      
   $ComputerName = $_.name
   
   try{Connect-WSMan -computername $ComputerName -ErrorAction SilentlyContinue}
   catch{ $FailCount = 1}

   if ($FailCount -ne 1) {
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
      $svc = Get-Service -Name 'Zabbix Agent' -ErrorAction SilentlyContinue
      $Ghostname = hostname
   
      if ($svc -eq $null){ write-host "$Ghostname Zabbix Agent nao instalado." -ForegroundColor Red }
      else { Write-Host $Ghostname $svc.name $svc.Status -ForegroundColor Blue }
      } 
   }  
   else { write-host "$ComputerName powershell nao conecta." -ForegroundColor Yellow }

   $FailCount = $null

 }
