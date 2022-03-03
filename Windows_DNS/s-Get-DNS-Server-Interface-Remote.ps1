 
 import-csv "C:\Temp\SLZ-SRV-new.txt" | foreach {
   
    $ComputerIPAddress = $_.srv
    $ComputerName = [System.Net.Dns]::GetHostEntry("$ComputerIPAddress").HostName 
    
    try{Connect-WSMan -computername $ComputerName -ErrorAction SilentlyContinue}
    catch{"Falha ao se conectar em $ComputerIPAddress"
     }
   
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-DnsClientServerAddress | where-object {($_.InterfaceAlias -notlike '*Loopback*') -and ($_.InterfaceAlias -notlike '*isatap*') -and ($_.ServerAddresses -ne $null) } | Select-Object PSComputerName,ServerAddresses}
   
      
   }
   