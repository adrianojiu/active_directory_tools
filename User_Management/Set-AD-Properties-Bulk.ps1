<#
.NOTES
Set properties on AD user based on csv file Set-AD-Properties-Bulk.csv.
   To add or remove properties that are changed it is necessary to adjust the CSV file and the Set-ADUser properties.
   It is necessary to adjust to the OR where the users are where "-SearchBase" will be adjusted.

  CSV example:

  samaccountname,City,Office,Division
  alearu,Rio de Janeiro, Rio Centro, RH

#>
            
Import-Module ActiveDirectory            

$users = Import-Csv -Path .\Set-AD-Properties-Bulk.csv
foreach ($user in $users) {            

    Get-ADUser -Filter "SamAccountName -eq '$($user.samaccountname)'" -Properties * -SearchBase "OU=EXAMPLE-Global,DC=EXAMPLEBR,DC=LOCAL" | 
     Set-ADUser -City $($user.City) -Office $($user.Office) -Division $($user.Division)
}
