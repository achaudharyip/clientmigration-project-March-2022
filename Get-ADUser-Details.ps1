<#
.SYNOPSIS
    Gather information of AD Users
.DESCRIPTION
    Gather information of AD Users to prepare and create a strategy for migrating the Users to a new domain
.EXAMPLE
    PS C:\> .\Get-ADUsers-Details.ps1
    The script connects to the source domain, gathers information for users, categorizes needed properties, and exports the properties to a csv file in a given order.
.INPUTS
    Inputs information for Domain and ComputerNames from COMPANY-AD-DOMAIN-LIST.csv and COMPANY-AD-USER-LIST.csv
.OUTPUTS
    Output csv file with information for following:
    UserName,FirstName,LastName,AccountEnabled,GroupMembership,PrimaryGroup,PrimaryGrpID,HomeDrive,HomeDirectory,CompanyUPN,SID,UserOUPath,GUIDInfo
.NOTES
    Import from csv files with information for Domain Controller Server and HostNames
#>

function Get-ADUSERDETAIL {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DOMAIN,
        [string]$USRACCOUNTS
    ) #end param
    process {
        get-aduser -Server $DOMAIN -Identity $USRACCOUNTS -Properties *
    }
}

$DOMList = import-csv -Path "C:\users\bsimigrate\Downloads\COMPANY-AD-DOMAIN-LIST.csv"
$USERLIST = Import-Csv -Path C:\USERS\bsimigrate\Downloads\COMPANY-AD-USER-LIST.csv
$DCSVR = $DOMList.SourceDomain
$CLIENTS = $USERLIST.UserName
#$DCSVR = "dcv.stratford.local"
#$USERS = "stratford.migrate","stratford.migrate2"
$Details = @()
foreach ($USER in $USERS) {
    $Details += Get-ADUSERDETAIL $DCSVR $USER
}

$USRResult = @()
ForEach ($Detail in $Details){
    If($Detail.Enabled -eq $true){
        $Enabled = "Yes"
        If($Detail.Enabled -eq $false){
            $Enabled = "No"
        }
    }
    $Group = ((($Detail.MemberOf -split ",OU=O365 Groups,OU=Stratford Staff") -replace "CN=", "") -replace ",Builtin", "") -replace ",DC=Stratford,DC=local", ""| Out-String
    $USRResult += New-Object -TypeName psobject -Property (@{PrimaryGroup=$Detail.PrimaryGroup;PrimaryGrpID=$Detail.primaryGroupID;HomeDrive=$Detail.HomeDrive;HomeDirectory=$Detail.HomeDirectory;Company=$Detail.Company;GroupMembership=$Group;UserName=$Detail.SamAccountName; AccountEnabled=$Enabled; FirstName=$Detail.GivenName; LastName=$Detail.Surname; UserOUPath=$Detail.DistinguishedName; SID=$Detail.SID; GUIDInfo=$Detail.ObjectGUID; UPN=$Detail.UserPrincipalName})
}


$USRResult|Select-Object -Property UserName,FirstName,LastName,AccountEnabled,GroupMembership,PrimaryGroup,PrimaryGrpID,HomeDrive,HomeDirectory,CompanyUPN,SID,UserOUPath,GUIDInfo|Export-Csv -Path c:\Path-to-Directory-for-output-csv-file\PreUserMigrationInfo.csv -NoTypeInformation