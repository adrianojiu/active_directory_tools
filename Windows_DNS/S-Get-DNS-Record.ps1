<#
    .Description
    Get DNS record in Windows server DNS.
    It should be run in a windows powershell.
#>

$DNSZone = "EXAMPLE.net"
$DSNRecord = ("brspdsrv1")          # For multiple records use this format ---> $DSNRecord = @("portal","brspsrdb001")
$DSNReverse = @("10.123.0.249")     # For multiple reverse records use this format ---> $DSNReverse = @("10.123.0.117","10.123.0.119","10.123.0.131")

# DNS server for lookup.
$DNSSRV = "10.123.7.20"

ForEach($iRecord in $DSNRecord){
    Get-DnsServerResourceRecord -ComputerName $DNSSRV -ZoneName $DNSZone -Name $iRecord
}

ForEach($iReverse in $DSNReverse){
    nslookup.exe -type=ptr $iReverse
}
