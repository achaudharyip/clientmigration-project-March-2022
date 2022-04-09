<#
.SYNOPSIS
    Gather information of AD Computers
.DESCRIPTION
    Gather information of AD Computers to prepare and create a strategy for migrating the computers to a new domain
.EXAMPLE
    PS C:\> .\Get-ADComputer-Details.ps1
    The script connects to the source domain, gathers information for computers, categorizes needed properties, and exports the properties to a csv file in a given order.
.INPUTS
    Inputs information for Domain and ComputerNames from COMPANY-AD-DOMAIN-LIST.csv and COMPANY-AD-HOST-LIST.csv
.OUTPUTS
    Output csv file with information for following:
    HostName,FQDN,IPAddress,OS,OSVersion,ServiceAccount,OUPath,SID,GUID,GroupID
.NOTES
    Import from csv files with information for Domain Controller Server and HostNames
#>

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

$DOMList = import-csv -Path C:\users\Username\Downloads\COMPANY-AD-DOMAIN-LIST.csv
$HOSTLIST = Import-Csv -Path C:\USERS\UserName\Downloads\COMPANY-AD-HOST-LIST.csv
$DCSVR = $DOMList.SourceDomain
$CLIENTS = $HOSTLIST.HostName
$Details = @()
foreach ($CLIENT in $CLIENTS) {
    $Details += Get-ADCOMPUTERDETAILS $DCSVR $CLIENT
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
$Result|Select-Object -Property HostName,FQDN,IPAddress,OS,OSVersion,ServiceAccount,OUPath,SID,GUID,GroupID|Export-Csv -Path c:\Path-to-Directory-for-output-csv-file\PreComputerMigrationInfo.csv -NoTypeInformation
