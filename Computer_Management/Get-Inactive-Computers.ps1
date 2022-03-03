<#
.NOTES
   Search in AD inactive computers by the number of days set in the variable $DaysInactive.
   Result is exported to the OLD_Computer.csv file in the folder where the script is run.
#>

import-module activedirectory  

#$domain = "EXAMPLE.CORP"  
$DaysInactive = 30
$time = (Get-Date).Adddays(-($DaysInactive)) 
  
#  Get all AD computers with lastLogonTimestamp less than our time.
Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp | 
  
#  Output hostname and lastLogonTimestamp into CSV.
select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | export-csv .\OLD_Computer.csv -notypeinformation
