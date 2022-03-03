# Get computers in specific OU and their Bitloker recovery password, just after export to a csv file.

$objComputerArray = Get-ADComputer -Filter * -SearchBase "OU=Corca-Sao Paulo,OU=Win 10,OU=Workstations,OU=Sao Paulo Corca,OU=South America,DC=EXAMPLE,DC=NET"

$objComputer = foreach ($OUBase in $objComputerArray.name) {            
    $OUSearchFor = "OU=Corca-Sao Paulo,OU=Win 10,OU=Workstations,OU=Sao Paulo Corca,OU=South America,DC=EXAMPLE,DC=NET"
    Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $OUSearchFor -Properties 'msFVE-RecoveryPassword'
}

$objComputer  | Export-Csv -Path C:\Temp\Bitlocker.csv -NoTypeInformation




