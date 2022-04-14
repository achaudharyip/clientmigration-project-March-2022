<#
.SYNOPSIS
    Uncheck User must change password at next logon
.DESCRIPTION
    After User Migration is compleded, User must change password at next logon, is enabled by default. Uncheck this option for all migrated users
.EXAMPLE
    PS C:\> .\Disable-ChangePassword.ps1
    The script connects to the target domain, checks to see if the "User must change password at next logon is checked", will uncheck if checked.
.INPUTS
    Inputs information for Domain and users from one csv file
.OUTPUTS
    Output csv file report was unchecked
.NOTES
    Import from csv files with information for Domain Controller Server and UserNames
#>

function Select-csvFile($startDir){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")|Out-Null

    $FileName = New-Object System.Windows.Forms.OpenFileDialog
    $FileName.InitialDirectory = $startDir
    $FileName.Filter = "All files (*.*)| *.*"
    $FileName.ShowDialog() | Out-Null
    $FileName.FileName
}

function Check-ChangePwdOption {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DOM,
        [string]$USRACCTS
    ) #end param
    process {
        Get-ADUser -Server $DOM -Identity $USRACCTS -Properties *
    }
}

function Disable-ChangePwdOption {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DOMAIN,
        [string]$USRACCOUNTS
    ) #end param
    process {
            Set-ADUser -Server $DOMAIN -Identity $USRACCOUNTS -ChangePasswordAtLogon $false
    }
}

$csvName = Select-csvFile
$LISTS = import-csv -Path $csvName
$Status = @()
ForEach ($LIST in $LISTS){
    $DCSVR = $LIST.Domain
    $USER = $LIST.UserName
    $Status += New-Object -TypeName psobject -Property (@{Changepwd=(Check-ChangePwdOption $DCSVR $USER).pwdlastset;UserName=$USER;DC=$DCSVR})
    }

$Details = @()
foreach ($ULIST in $STATUS) {
    if($ULIST.Changepwd -eq 0){
        Disable-ChangePwdOption $ULIST.DC $ULIST.UserName
     }
}

$FinalStatus = @()
ForEach ($LIST in $LISTS){
    $DCSVR = $LIST.Domain
    $USER = $LIST.UserName
    $FinalStatus += New-Object -TypeName psobject -Property (@{Changepwd=(Check-ChangePwdOption $DCSVR $USER).pwdlastset;UserName=$USER;DC=$DCSVR})
    }

$FinalResult = @()
ForEach ($Final in $FinalStatus){
    If ($Final.Chagedowd -ne 0){
        $ChgPwdLO = "Disabled"
        $FinalResult += New-Object -TypeName PSObject -Property (@{UserName=$Final.UserName;ChangePasswordAtLogOn=$ChgPwdLO;DomainController=$Final.DC})       
    }
}

$Date = Get-Date -Format mmddyy
$RptName = "PostMigrationReport-" + $Date + ".csv"
$UserProfile = (Get-ChildItem -Path Env:\USERPROFILE).Value
$DownloadsPath = $UserProfile + '\Downloads'
$RptsPath = $DownloadsPath + '\' + 'MigrationReports'
$RptFilePath = $RptsPath + "\" + $RptName
If((Test-Path -Path $RptsPath) -ne $true){
    New-Item -Path $DownloadsPath -ItemType Directory -Name 'MigrationReports'
}


$FinalResult|Select-Object -Property UserName,ChangePasswordAtLogOn,DomainController|Export-Csv -Path $RptFilePath -Append -NoTypeInformation