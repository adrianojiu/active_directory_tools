import-csv "C:\Temp\SLZ-SRV-new.txt" | foreach {
 
  $hostN = Invoke-Command -ComputerName $_.srv -ScriptBlock {hostname}
  $DNSIF = Invoke-Command -ComputerName $_.srv -ScriptBlock {Get-DnsClientServerAddress | where-object  {($_.InterfaceAlias -notlike '*Loopback*') -and ($_.InterfaceAlias -notlike '*isatap*') -and ($_.ServerAddresses -ne $null) }}
   
  if ([string]$DNSIF.ServerAddresses -inotlike '*10.123.7.23*') {
 
   Write-Host $hostN
    
   # variavel $Using:DNSIF passa para a sessão remota uma variavel local para uso deve ser usado o $Using:
   Invoke-Command -ComputerName $hostN -ScriptBlock { Set-DnsClientServerAddress -Interfaceindex $Using:DNSIF.InterfaceIndex -ServerAddresses ("10.123.7.23","10.120.95.21","10.70.0.20","10.71.0.20") }
    
 
  }
  else {
    Write-Host "Servidor DNS OK." -ForegroundColor Blue
  }
 }
 
