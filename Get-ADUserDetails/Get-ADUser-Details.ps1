<#
.SYNOPSIS
    Gather information of AD Users
.DESCRIPTION
    Gather information of AD Users to prepare and create a strategy for migrating the Users to a new domain
.EXAMPLE
    PS C:\> .\Get-ADUsers-Details.ps1
    The script connects to the source domain, gathers information for users, categorizes needed properties, and exports the properties to a csv file in a given order.
.INPUTS
    Inputs information for Domain and ComputerNames from YMCA-AD-DOMAIN-LIST.csv and YMCA-AD-USER-LIST.csv
.OUTPUTS
    Output csv file with information for following:
    UserName,FirstName,LastName,AccountEnabled,GroupMembership,PrimaryGroup,PrimaryGrpID,HomeDrive,HomeDirectory,CompanyUPN,SID,UserOUPath,GUIDInfo
.NOTES
    Import from csv files with information for Domain Controller Server and HostNames
#>

function Select-csvFile($startDir){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")|Out-Null

    $FileName = New-Object System.Windows.Forms.OpenFileDialog
    $FileName.InitialDirectory = $startDir
    $FileName.Filter = "All files (*.*)| *.*"
    $FileName.ShowDialog() | Out-Null
    $FileName.FileName
}

# 
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

$csvName = Select-csvFile
$LISTS = import-csv -Path $csvName

$Details = @()
foreach ($LIST in $LISTS) {
    $DCSVR = $List.Domain
    $USER = $LIST.UserName
    $Details += Get-ADUSERDETAIL $DCSVR $USER
}

$Date = Get-Date -Format MMdyy
$RptName = "PreUserMigrationReport-" + $Date + ".csv"
$UserProfile = (Get-ChildItem -Path Env:\USERPROFILE).Value
$DownloadsPath = $UserProfile + '\Downloads'
$RptsPath = $DownloadsPath + '\' + 'PreMigrationReports'
$RptFilePath = $RptsPath + "\" + $RptName
If((Test-Path -Path $RptsPath) -ne $true){
    New-Item -Path $DownloadsPath -ItemType Directory -Name 'PreMigrationReports'
}
$Result = @()
ForEach ($Detail in $Details){
    If($Detail.Enabled -eq $true){
        $Enabled = "Yes"
        If($Detail.Enabled -eq $false){
            $Enabled = "No"
        }
    }
    $Group = ((($Detail.MemberOf -split ",OU=O365 Groups,OU=Stratford Staff") -replace "CN=", "") -replace ",Builtin", "") -replace ",DC=Stratford,DC=local", ""| Out-String
    $Result += New-Object -TypeName psobject -Property (@{PrimaryGroup=$Detail.PrimaryGroup;PrimaryGrpID=$Detail.primaryGroupID;HomeDrive=$Detail.HomeDrive;HomeDirectory=$Detail.HomeDirectory;Company=$Detail.Company;GroupMembership=$Group;UserName=$Detail.SamAccountName; AccountEnabled=$Enabled; FirstName=$Detail.GivenName; LastName=$Detail.Surname; UserOUPath=$Detail.DistinguishedName; SID=$Detail.SID; GUIDInfo=$Detail.ObjectGUID; UPN=$Detail.UserPrincipalName})
}


$Result|Select-Object -Property UserName,FirstName,LastName,AccountEnabled,GroupMembership,PrimaryGroup,PrimaryGrpID,HomeDrive,HomeDirectory,CompanyUPN,SID,UserOUPath,GUIDInfo|Export-Csv -Path $RptFilePath -Append -NoTypeInformation