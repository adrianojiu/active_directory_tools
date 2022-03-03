 
 import-csv "C:\Temp\SLZ-SRV.txt" | foreach {
   
    $ComputerIPAddress = $_.srv
    $ComputerName = [System.Net.Dns]::GetHostEntry("$ComputerIPAddress").HostName 
    
    try{Connect-WSMan -computername $ComputerName}
    catch{"Falha ao se conectar em $ComputerIPAddress"
    break }
    
    $DNSIF =Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-DnsClientServerAddress | where-object  {($_.InterfaceAlias -notlike '*Loopback*') -and ($_.InterfaceAlias -notlike '*isatap*') -and ($_.ServerAddresses -ne $null) }}
       
    if ([string]$DNSIF.ServerAddresses -inotlike '*10.123.7.23*') {
      Write-Host $ComputerName $DNSIF.ServerAddresses
      }
   
   }