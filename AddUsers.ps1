#Import active directory module for running AD cmdlets
Import-Module activedirectory
$File = Read-Host "What file is being used to add new users?" 
#Store the data from ADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv $File
$UsersAttempted = 0 #Number of attempted account creations
$UsersCreated = 0 #Number of confirmed account creations
$Confirmation = ""
#Loop through each row containing user details in the CSV file 
# used to create a file for account creation log
# taking into consideration if the account creation script
# has already been ran for the day
$filecounter = 1 # used to determine if file version is in use 
$date = Get-Date -format M-d-yyyy
$filename = "C:\Users\Administrator\Desktop\Logs\Account Creation\AccountCreate_$date" + "v$filecounter.txt"
if((Test-Path $filename))
{

    while(Test-Path $filename)
    {
            
        $newfilename = $filename.Trim("v$filecounter.txt")
        $filecounter = [int]$filecounter + 1
        $newfilename = $newfilename + "v$filecounter.txt"
            
        if((Test-Path $newfilename) -eq $false)
        {
            New-Item $newfilename -ItemType file
            Write-Output "$filename already exists"      
            Write-Output "$newfilename created instead"
            $filename = $newfilename
            break
        }
            
            
        $filename = $newfilename
    }
}
else
{
    New-Item $filename -ItemType file      
}
foreach ($User in $ADUsers)
{
	#Read user data from each field in each row and assign the data to a variable as below
    $UsersAttempted = $UsersAttempted + 1
	$Username 	= $User.username
	$Password 	= $User.password
	$Firstname 	= $User.firstname
	$Lastname 	= $User.lastname
	$Type 		= $User.type #This field refers to the OU the user account is to be created in
    $global:OU  = ""
	#Check to see if the user already exists in AD
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 #If user does exist, give a warning
		
         $Confirmation = $Confirmation + "A user account with username $Username already exist in Active Directory.`r`n"
         
	}
	else
	{

        switch($Type)
        {

            "Student" {$global:OU += "OU=Students,OU=Perry,DC=perry,DC=com"}
            "Staff" {$global:OU += "OU=Staff,OU=Perry,DC=perry,DC=com"}
            "Faculty" {$global:OU += "OU=Faculty,OU=Perry,DC=perry,DC=com"}

        }
		#User does not exist then proceed to create the new user account
        #Account will be created in the OU provided by the $OU variable read from the CSV file
		New-ADUser `
            -SamAccountName $Username `
            -EmailAddress "$Username@perry.com" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $global:OU `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) 
            $UsersCreated = $UsersCreated + 1
            $Confirmation = $Confirmation + "Account for $Username succesfully created `r`n"
    }
}
$CurrentDateTime = Get-Date -Format g
Write-Output "Log file created on: $CurrentDateTime`r`n" | Add-Content $filename
Write-Output "Accounts Attempted: $UsersAttempted `r" | Add-Content $filename
Write-Output "Accounts Created: $UsersCreated `r" | Add-Content $filename
Write-Output $Confirmation | Add-Content $filename
Invoke-Item $filename