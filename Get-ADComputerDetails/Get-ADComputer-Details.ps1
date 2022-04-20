<#
.SYNOPSIS
    Gather information of AD Computers
.DESCRIPTION
    Gather information of AD Computers to prepare and create a strategy for migrating the computers to a new domain
.EXAMPLE
    PS C:\> .\Get-ADComputer-Details.ps1
    The script connects to the source domain, gathers information for computers, categorizes needed properties, and exports the properties to a csv file in a given order.
.INPUTS
    Inputs information for Domain and ComputerNames from YMCA-AD-DOMAIN-LIST.csv and YMCA-AD-HOST-LIST.csv
.OUTPUTS
    Output csv file with information for following:
    HostName,FQDN,IPAddress,OS,OSVersion,ServiceAccount,OUPath,SID,GUID,GroupID
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

function Get-ADCOMPUTERDETAILS {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DOMAIN,
        [string]$HOSTNAMES
    ) #end param
    process {
        get-adcomputer -Server $DOMAIN -Identity $HOSTNAMES -Properties *
    }
}

$csvName = Select-csvFile
$LISTS = import-csv -Path $csvName

$Details = @()
foreach ($LIST in $LISTS) {
    $DCSVR = $LIST.Domain
    $CLIENT = $LIST.HostName
    $Details += Get-ADCOMPUTERDETAILS $DCSVR $CLIENT
}

$Date = Get-Date -Format MMddyy
$RptName = "PreHostMigrationReport-" + $Date + ".csv"
$UserProfile = (Get-ChildItem -Path Env:\USERPROFILE).Value
$DownloadsPath = $UserProfile + '\Downloads'
$RptsPath = $DownloadsPath + '\' + 'PreMigrationReports'
$RptFilePath = $RptsPath + "\" + $RptName
If((Test-Path -Path $RptsPath) -ne $true){
    New-Item -Path $DownloadscPath -ItemType Directory -Name 'PreMigrationReports'
}

$Result = @()
ForEach ($Detail in $Details){
    If($Detail.ServiceAccount -eq '{}'){
        $SVCACCT = "Null"
        If($Detail.ServiceAccount -ne $null){
            $SVCACCT = $Detail.ServiceAccount
        }
    }
    $Result += New-Object -TypeName psobject -Property (@{FQDN=$Detail.DNSHostName;OUPath=$Detail.CanonicalName;HostName=$Detail.SamAccountName;IPAddress=$Detail.IPv4Address;SID=$Detail.SID;OS=$Detail.OperatingSystem;OSVersion=$Detail.OperatingSystemVersion;ServiceAccount=$SVCACCT;GUID=$Detail.ObjectGUID;GroupID=$Detail.primaryGroupID})
}
$Result|Select-Object -Property HostName,FQDN,IPAddress,OS,OSVersion,ServiceAccount,OUPath,SID,GUID,GroupID|Export-Csv -Path $RptFilePath -Append -NoTypeInformation
