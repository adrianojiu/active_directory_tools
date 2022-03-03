<#
.SYNOPSIS
    Script changes the status of accounts that are in the CSV file to disabled.

.NOTES
    There are two options of "Option with -LIKE" that uses regular expression and if the username indicated in the CSV file is,
    found anywhere in the user field the account will be disabled.
    Option "Option with -EQ" it takes the exact name that is in the CSV file and disables the account in AD.
    Use only one option to comment the line that is not used.


CSV example:

account
Aaron
Abraham
Acea
Adam
Aidan
Ainslee
Alan
Aleen

-- You must create a csv file(example is accounts-dis.csv), the first line must be "account" string it is mandatory.
#>


# Option one using -LIKE, read notes to mor info.
Import-Csv .\accounts-dis.csv | ForEach-Object { Get-ADUser -Filter "Name -like '*$($_.account)*'" | Disable-ADAccount }

# Option two -EQ, read notes to mor info.
Import-Csv .\accounts-dis.csv | ForEach-Object { Get-ADUser -Filter "Name -like '$($_.account)'" | Disable-ADAccount }

# The csv file must be in the same location as the file.
