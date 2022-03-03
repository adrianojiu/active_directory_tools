<#
.NOTES
  Shows users(based in SamAccountName) that are in the imported CSV (.\Get-AD-User-Bulk.csv) and properties that are after the "Select-Object".
  The selected properties are exported to a CSV file "temp.csv" in the folder where the script is.
 
CSV example:

jose
Aaron
Abraham
Acea
Adam
Aidan
Ainslee
Alan
Aleen

#>

$users = Import-Csv -Path .\Get-AD-User-Bulk.csv
foreach ($user in $users) {            
    Get-ADUser -Identity $user.SamAccountName -Properties * |            
     Select-Object DisplayName,sn,givenName,name,initials,SamAccountName,Office,l,company,City,st,co,Department,streetAddress,mail,telephoneNumber,userPrincipalName,distinguishedName,whenCreated |
      Export-Csv c:\temp\temp.csv -Append -Encoding UTF8 -NoTypeInformation -Delimiter ";"          
    }


  
