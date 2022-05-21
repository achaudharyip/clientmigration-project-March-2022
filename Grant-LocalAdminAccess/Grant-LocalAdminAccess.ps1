<#
.SYNOPSIS
    Grant Local Admin Access
.DESCRIPTION
    Grant User performing migration to multiple computers remotely
.EXAMPLE
    PS C:\> .\Grant-LocalAdminAccess.ps1
    Connects to remote machine and adds inputed user account to local admin group of remote computers
.INPUTS
    Inputs information for Hosts and users from one csv file. Get Credential for Domain Admin or permissions to change access on computers in source domain.
    UserAccounts must be in the format: Domain\UserName
.OUTPUTS
    Output csv file report Account is added on remote computer as success or failed
.NOTES
    Import from csv files with information for Domain Controller Server, UserNames, and HostNames
#>

Clear-Host
Add-Type -AssemblyName PresentationFramework
function Select-csvFile($startDir){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")|Out-Null

    $FileName = New-Object System.Windows.Forms.OpenFileDialog
    $FileName.InitialDirectory = $startDir
    $FileName.Filter = "All files (*.*)| *.*"
    $FileName.ShowDialog() | Out-Null
    $FileName.FileName
}

function Set-Path($startdir="") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $Directory = New-Object System.Windows.Forms.FolderBrowserDialog
    $Directory.Description = "Select the path to the grant-localadminaccess.ps1 directory"
    $Directory.rootfolder = "MyComputer"
    $Directory.SelectedPath = $startdir

    if($Directory.ShowDialog() -eq "OK")
    {
        $adminacesspath += $Directory.SelectedPath
    }
    return $Directory
}
Write-Host "Select the path where the ps1 file is located..." -ForegroundColor Green
$path = (Set-Path).SelectedPath
Write-Host "Enter the Domain Admin Credentials for the domain..." -ForegroundColor Green
$cred = Get-Credential
Write-Host "Settig full path for psexec.exe..." -ForegroundColor Green
$psexec = (Get-ChildItem -Path $path "psexec.exe").Name
Write-Host "Select the csv file with HostName and credentials to be added to the local Administrators Group..." -ForegroundColor Green  
$csvFile = Select-csvFile
Write-Host "Importing the csv File..." -ForegroundColor Green
$LISTS = Import-Csv $csvFile -Header HostName, UserName
$HOSTS = $LISTS.HostName
$USER = $cred.UserName
$P = $Cred.GetNetworkCredential().Password
Write-Host "Setting Reports Path Name and Directory Path..." -ForegroundColor Green
$Date = Get-Date -Format MMddyy
$RptName = "AddAAccountAdminGrp_" + $Date + ".csv"
$UserProfile = (Get-ChildItem -Path Env:\USERPROFILE).Value
$DownloadsPath = $UserProfile + '\Downloads'
$RptsPath = $DownloadsPath + '\' + 'PreMigrationReports'
$RptFilePath = $RptsPath + "\" + $RptName
If((Test-Path -Path $RptsPath) -ne $true){
    New-Item -Path $DownloadscPath -ItemType Directory -Name 'PreMigrationReports'
}
Clear-Host
ForEach($CNAME in $HOSTS){
    If((Test-Connection -ComputerName $CNAME -Quiet) -eq $false){
        Write-Host "Set path to $path..." -ForegroundColor Green
        Set-Location -Path $path
        $Remote = "\\" + $CNAME
        $ADMPath = $Remote + '\admin$'
        Write-Host "Starting temporary net connection to $ADMPath" -ForegroundColor Green
        net use $ADMPath /user:$USER $P
        Write-Host "Enabling winrm on $CNAME..." -ForegroundColor Green
        Start-Process -Wait -PSPath $PSexec -ArgumentList "-u $cred.UserName -p $cred.password $Remote -h -s winrm.cmd quickconfig -q" -Verb RunAs
        Write-Host "Enabled WinRM on $CNAME..." -ForegroundColor Green
        Start-Sleep -Seconds 60 -Verbose
        Write-Host "Waiting until WinRM on $CNAME is complete" -ForegroundColor Yellow
        Start-Sleep -Seconds 60 -Verbose
        Write-Host "Enabling PSRemoting on $CNAME..." -ForegroundColor Green
        Start-Process -Wait -PSPath $PSexec -ArgumentList "-u $cred.UserName -p $cred.Password $Remote -c PowerShell.exe enable-psremoting -force" -Verb RunAs
        Write-Host "Enabled PSRemoting on $CNAME" -ForegroundColor Green
        Write-Host "Enabling and setting the execution policy on $CNAME to RemoteSigned..." -ForegroundColor Green
        Start-Process -Wait -PSPath $PSexec -ArgumentList "-u $cred.UserName -p $cred.Password $Remote -c PowerShell.exe set-executionpolicy RemoteSigned -force" -Verb RunAs
        Write-Host "Enabled/ Set the execution policy on $CNAME to RemoteSigned" -ForegroundColor Green
        Write-Host "Deleting temporary net connection to $ADMPath" -ForegroundColor Green
        net use $ADMPath /DELETE
        IF((Test-WSMan -ComputerName $CNAME) -ne $false){
            Write-Host "PSRemoting on $CNAME is now working" -ForegroundColor Green
            }
        }
    }

$Status = @()
ForEach ($LIST in $LISTS){
    If((Test-Connection -ComputerName $LIST.HostName -Quiet) -eq $true){
        $HOSTNAME = $LIST.HostName
        $USERNAME = $LIST.UserName
        If((Test-WSMan -ComputerName $HOSTNAME) -ne $false){
            Write-Host "Starting a new remote session to $HOSTNAME" -ForegroundColor Green
            $S = New-PSSession -ComputerName $HOSTNAME -Credential $CRED
            Write-Host "Adding $USERNAME on $HOSTNAME to the local Administrators Group..." -ForegroundColor Green
            Invoke-Command -Session $S -ScriptBlock { Add-LocalGroupMember -Group "Administrators" -Member $USING:UserName }
            $CheckSuccess = Invoke-Command -Session $S -ScriptBlock { Get-LocalGroupMember -Group "Administrators" -Member $args[0] } -ArgumentList $USERNAME
            If($CheckSuccess.Name -eq $USERNAME){
                $ACCTSTATUS = "True"
            }
            Else {
                $ACCTSTATUS = "False"
            }
            Remove-PSSession $S
            $Status += New-Object -TypeName psobject -Property (@{HostName=$HOSTNAME;Status=$ACCTSTATUS;UserName=$USER;Group=$GROUP})
            }
    }
}
Write-Host "Writing the status results to file..." -ForegroundColor Green
$Status|Select-Object -Property HostName,Status,UserName,Group|Export-Csv -Path $RptFilePath -Append -NoTypeInformation
