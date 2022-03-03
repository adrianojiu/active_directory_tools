<#
        
    Purpose: 
        This script has 3 separate functions:

            -It deletes computer accounts that have not logged into AD for 2 years
            -It moves computers to an inactive OU if the computer has not logged into AD for the last year
            -It computers back to original OU if the computer has logged into AD within the last year

        It also serves as a reporting tool that will email the details of:
            -Computers that have been deleted
            -Computers moved to inactive OU
            -Computers moved back to original OU
            -Any details on a script failure
#>


# Variables to set
$SMTPServer = "my-smtp-server@example.com"
$FROMEmailAddress = "sender-email-addresses@example.com"
$TOEmailAddress = "receiver-email@example.com"
$TOPLevelOU = "DC=EXAMPLE,DC=local"
$IdleComputersOU = "OU=Computers_Disabled,DC=EXAMPLE,DC=local"
$DomainControllerServer = "dc-hostname.EXAMPLE.local"

# Creates a function to send a report
Function Send-Report {
    
    #Input Parameters
    Param ([string]$outputFile,[string]$subject,[string]$body)
    
    $att = New-Object Net.Mail.Attachment($outputFile)
    $msg = New-Object Net.Mail.MailMessage
    $smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
    $msg.From = $FROMEmailAddress
    $msg.To.Add($TOEmailAddress)
    $msg.Subject = $subject
    $msg.Body = $body
    $msg.Attachments.Add($att)
    $smtp.Send($msg)
    $att.Dispose()

}

# Move computers from default OU to OU from EXAMPLE computers.
Get-ADComputer -SearchBase "CN=Computers,DC=EXAMPLE,DC=local" -Filter * | Move-ADObject -TargetPath "OU=computers,OU=EXAMPLE,OU=EXAMPLESP,OU=EXAMPLE_Global,DC=EXAMPLE,DC=local"

#####################################################################
# Deletes Computers that have not logged into AD for 1 year
# Nao esta deletando apenas logando computadores q seriam deletados.
#####################################################################
# Execucao 1
#####################################################################
try{
    # Sets the threshold to 1 years
    $deleteDateCutoff = (Get-Date).AddDays(-365)
    
    # Initializes array of computers that have not logged into AD for 1 year and 3 months
    $nonExistingComputers = Get-ADComputer -SearchBase $TOPLevelOU -Filter {LastLogonTimeStamp -lt $deleteDateCutoff}  -Properties * | Sort LastLogonTimeStamp
    
    # If the array is empty
    if($nonExistingComputers -eq $null)
    {
        # Send Mail Message
        Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 1 - Inactive Computer Script" -SmtpServer $SMTPServer -Body "The script ran successfully, but there are no computer accounts which have been idle more than 365 days."
    }

    # If there are computers in the Array
    else
    {
        # Loop through each computer in the array
        foreach ($computer in $nonExistingComputers)
        {
            # Remove the computer object from Active Directory
            Remove-ADComputer -Identity $computer.Name -WhatIf 
        }
        # Create a report from the Array
        $nonExistingComputers | FT Name, LastLogonTimeStamp, @{Label="Date Deleted from AD"; Expression={(get-date)}} -AutoSize | Out-File C:\Run-Script\Reports\Deleted_Computers_365.txt -Append

        # Send the report
        Send-Report -outputFile "C:\Run-Script\Reports\Deleted_Computers_365.txt" -subject "Execucao 1 - Deleted Computers Ran Successfully" -body "Attached is a the log file containing ALL computers deleted from Active Directory."
    }
}
catch{

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 1 - Delete Computer Failed to Run" -SmtpServer $SMTPServer -Body "The script was unable to be processed due to this item: $FailedItem. The error message was $ErrorMessage"
}


#####################################################################
# Moves Computers to Inactive Computer OU if the computer has not logged on for the 60 days.
#####################################################################
# Execucao 2
#####################################################################
try{
    # Sets the Threshold to 60 days.
    $idleDateCutoff = (Get-Date).AddDays(-60)
    
    # Initializes array of computers within CCO Computers than have not logged in for 60 days.
    $idleComputers = Get-ADComputer -SearchBase $TOPLevelOU -Properties LastLogonTimeStamp,extensionattribute1 -Filter {LastLogonTimeStamp -lt $idleDateCutoff} | Where-Object {$_.DistinguishedName -notlike $IdleComputersOU} | Sort LastLogonTimeStamp 
    $MovedComputers = New-Object System.Collections.ArrayList

    if($idleComputers -eq $null)
    {
        Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 2 - Inactive Computer Script" -SmtpServer $SMTPServer -Body "The script ran successfully, but there are no computer accounts to move to the Inactive Computer OU at this current time."
    }
    else
    {
        # Loops through each computer in the idleComputers array
        foreach ($computer in $idleComputers)
        {
    
            # Targets specifically the OU from within the Distinguished Name
            $OUSplit = $computer.DistinguishedName -split ",", 2

            # Clears the current extension attribute to ensure a the OU is saved
            # Otherwise you cannot 'add' an attribute while there is one present
            Set-ADComputer $computer -Clear "extensionattribute1" -Server $DomainControllerServer
        
            # Saves the current OU into the extension attribute
            Set-ADComputer $computer -add @{extensionattribute1 = $OUSplit[1]}  -Server $DomainControllerServer

            # Reinitializes computers including the new extensionattribute
            $tempC = get-adcomputer $computer.name -properties name,LastLogonTimeStamp,extensionattribute1 -Server $DomainControllerServer

            # Adds the moved computer to an Array for Reporting
            $MovedComputers.Add($tempC)

            # Targets the current computer in the array by the distinguished name and moves the computer object into the InactiveComputer OU
            Move-ADObject -Identity $computer.DistinguishedName -TargetPath $IdleComputersOU -Server $DomainControllerServer
        }

        # Appends all computers moved to a file for reporting.
        # Each time the script runs, new computers moved will be added 
        $MovedComputers | FT Name, LastLogonTimeStamp, @{Label="Date Moved to Inactive"; Expression={(get-date)}}, @{Label="Original Organizational Unit"; Expression={$_.extensionAttribute1}} -AutoSize | Out-File C:\Run-Script\Reports\Inactive_Computers_60.txt -Append
    }
    # Send Report
    Send-Report -outputFile C:\Run-Script\Reports\Inactive_Computers_60.txt -subject "Execucao 2 - Inactive Computer Script Successful" -body "This script the last Log On Date for the computer against AD and if the computer has not logged on within the last 60 days, the computer object is moved to the Inactive Computers OU. Attached is a LOG file containing those computers"

}
catch{

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 2 - Inactive Computer Failed to Run" -SmtpServer $SMTPServer -Body "The script was unable to be processed due to this item: $FailedItem. The error message was $ErrorMessage"
}


#####################################################################
# Moves Computers to Inactive Computer OU if the computer has not logged on.
#####################################################################
#Execucao 3
#####################################################################
try{
    $nologonComputers = Get-ADComputer -SearchBase $TOPLevelOU -Properties lastLogonDate,extensionattribute1 -Filter {LastLogonDate -notlike "*" -and Enabled -eq $true } | Sort LastLogonDate
    $MovedComputers = New-Object System.Collections.ArrayList

    if($nologonComputers -eq $null)
    {
        Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 3 - Inactive Computer Script" -SmtpServer $SMTPServer -Body "The script ran successfully, but there are no computer accounts to move to the No Logon Computer OU at this current time."
    }
    else
    {
        # Loops through each computer in the idleComputers array
        foreach ($computer in $nologonComputers)
        {
    
            # Targets specifically the OU from within the Distinguished Name
            $OUSplit = $computer.DistinguishedName -split ",", 2

            # Clears the current extension attribute to ensure a the OU is saved
            # Otherwise you cannot 'add' an attribute while there is one present
            Set-ADComputer $computer -Clear "extensionattribute1" -Server $DomainControllerServer
        
            # Saves the current OU into the extension attribute
            Set-ADComputer $computer -add @{extensionattribute1 = $OUSplit[1]}  -Server $DomainControllerServer

            # Reinitializes computers including the new extensionattribute
            $tempC = get-adcomputer $computer.name -properties name,LastLogonDate,extensionattribute1 -Server $DomainControllerServer

            # Adds the moved computer to an Array for Reporting
            $MovedComputers.Add($tempC)

            # Targets the current computer in the array by the distinguished name and moves the computer object into the InactiveComputer OU
            Move-ADObject -Identity $computer.DistinguishedName -TargetPath $IdleComputersOU -Server $DomainControllerServer
        }

        # Appends all computers moved to a file for reporting.
        # Each time the script runs, new computers moved will be added 
        $MovedComputers | FT Name, LastLogonDate, @{Label="Date Moved to Inactive"; Expression={(get-date)}}, @{Label="Original Organizational Unit"; Expression={$_.extensionAttribute1}} -AutoSize | Out-File C:\Run-Script\Reports\nologon_Computers.txt -Append
    }
    # Send Report
    Send-Report -outputFile C:\Run-Script\Reports\nologon_Computers.txt -subject "Execucao 3 - Inactive Computer Script Successful" -body "This script the last Log On Date for the computer against AD and if the computer has not logged on , the computer object is moved to the Inactive Computers OU. Attached is a LOG file containing those computers"

}
catch{

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 3 - No logon Computer Failed to Run" -SmtpServer $SMTPServer -Body "The script was unable to be processed due to this item: $FailedItem. The error message was $ErrorMessage"
}


####################################################################
# Moves Computers back to original OU if the computer has logged on within the last 30 days.
####################################################################
#Execucao 4
####################################################################
try{

    # Sets Threshold to 30 days.
    $activeDateCutoff = (Get-Date).AddDays(-30)

    # Initializes array of computers that are in the Inactive Computer OU and have logged into the domain within the last 30 days
    $activeComputers = Get-ADComputer -SearchBase $IdleComputersOU -Properties * -Filter {LastLogonTimeStamp -gt $deleteDateCutoff} 

    # If there are no active computers within the Inactive Computer OU
    if($activeComputers -eq $null)
    {
        # Send Mail Message
        Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 4 - Active Computer Script" -SmtpServer $SMTPServer -Body "The script ran successfully, but there are no computer accounts that have become Active since moving to the Inactive Computer OU."
    }
    # If there are active computers within the Inactive Computer OU
    else
    {
        # Loop through each computer in the activeComputers Array
        foreach ($activecomputer in $activeComputers){
    
            # Move the current computer within the array back to its original OU
            Move-ADObject -Identity $activecomputer.DistinguishedName -TargetPath $activecomputer.extensionAttribute1 -Server $DomainControllerServer

        }

        # Append results to file
        $activeComputers | FT Name, LastLogonTimeStamp, @{Label="Execucao 4 - Date Moved to Active"; Expression={(get-date)}}, @{Label="Original Organizational Unit"; Expression={$_.extensionAttribute1}} -AutoSize | Out-File C:\Run-Script\Reports\Active_Computers.txt -Append
        
        # Send Report
        Send-Report -outputFile "C:\Run-Script\Reports\Active_Computers.txt" -subject "Execucao 4 - Reactivated Computers" -body "This script checks last Log On Date for the computers in the InactiveComputer OU and if the computer has logged on within the last 30 days, the computer object is moved to its original OU. Attached is a LOG file containing those computers"
    }
}
catch{    

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Send-MailMessage -From $FROMEmailAddress -To $TOEmailAddress -Subject "Execucao 4 - Active Computer Failed to Run" -SmtpServer $SMTPServer -Body "The script was unable to be processed due to this item: $FailedItem. The error message was $ErrorMessage"
}







####################################################################
# Disable computer account moved accounts 
####################################################################3

Get-ADComputer -SearchBase "OU=Computadores_Desabilitados,DC=EXAMPLE,DC=local" -Filter * | Set-ADComputer -Enabled:$false
