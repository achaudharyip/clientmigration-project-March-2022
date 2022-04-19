<#
.SYNOPSIS
    Verify Password Complexity
.DESCRIPTION
    Verify if the new passwords created meet Active Directory Requirements
.EXAMPLE
    PS C:\> .\VerifyComplexity.ps1
.INPUTS
    Inputs information for UserNames and new Passwords from a csv file.
.OUTPUTS
    Output report csv file with following information:
    UserName: user names
    MeetsMinimumLengthRequirement: Yes/No
    IncludesSpecialCharacters: Yes/No
    PwdMatchesUserName: Yes/No
    MeetsPasswordRequirement: Yes/No
    ContainsForbiddenPassword: Yes/No
    PasswordChangeRequired: Yes/No
.NOTES
    Import csv file with usernames and passwords to verify if they meet the requirements of the Domain Policy
#>

Clear-Host
Write-Host "{{ VERIFY IF PASSWORD MEETS COMPLEXITY REQUIREMENT }}`n`nPassword must meet the following Complexity requirements per the new Active Directory Policy: `n`nInclude at least one upper case letter [A-Z].`nInclude at least one lower case letter [a-z].`nInclude at least one number between [0-9].`nAnd, include at least one special character (!,@,#,%,^,&,$,_,-)`nPassword length must be at a minimum of 8 characters."`n`n`n"The script will import the csv selected and will check to see if the new password meets the complexity requirement according to the new domain policy"
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
    $Directory.Description = "Select the path to the psexec and grant-localadminaccess.psq directory"
    $Directory.rootfolder = "MyComputer"
    $Directory.SelectedPath = $startdir

    if($Directory.ShowDialog() -eq "OK")
    {
        $adminacesspath += $Directory.SelectedPath
    }
    return $Directory
}

$csvName = Select-csvFile
$LISTS = import-csv -Path $csvName
$Status = @()
foreach($LIST in $LISTS){
    $UserName = $LIST.UserName
    $PWD = $LIST.ProposedPwd
    $User = $UserName.ToLower()
    $MinLength = "8"
    $Forbiddenpwds = "Password","Password!","P@ssword","P@ssw0rd","P@$sword","P@$$word",,"P@$$word"
        If($PWD -contains $Forbiddenpwds){
            $Forbidden = $true
            Write-Host "The password for $UserName contains a Forbidden Password. Change the password" -ForegroundColor Red
        } 
        Else{
            $Forbidden = $false
            Write-Host "The password for $UserName does not contain a Forbidden Password." -ForegroundColor Green
            }
    Write-Host "Checking the minimum password length for $UserName..." -ForegroundColor Magenta
    if($PWD.Length -ge $MinLength){
        $Length = $true
        Write-Host "The password for $UserName meets the minimum length requirement" -ForegroundColor Green
        }
    if($PWD.Length -lt $MinLength){
        $Length = $false
        Write-Host "The password for $UserName failed to meet the minimum length requirement" -ForegroundColor Red
        }
    Write-Host "Checking to see if the password for $UserName contains any parts of Name..." -ForegroundColor Magenta
    if($PWD.ToLower().Contains($User.Substring(0,3))){
        $PWDMatch = $true
        Write-Host "The password for user $UserName failed to meet the Domain Complexity requirement. The password must be changed, the password contains part of the username" -ForegroundColor Red
        }
        Else{
            $PWDMatch = $false
            Write-Host "The password for user $UserName meets the Domain Complexity requirement. The password does not contain part of the username" -ForegroundColor Green
        }
    Write-Host "Checking to see if the password for $UserName contains lower case, Upper case, numbers and special characters..." -ForegroundColor Magenta    
    if((($PWD -cmatch '[a-z]') -and ($PWD -cmatch '[A-Z]') -and ($PWD -cmatch '\d') -and ($PWD -match '!|@|#|%|^|&|$|_|-'))){
       $Contains = $true
       Write-Host "The password for user $UserName meets the Domains Complexity requirement" -ForegroundColor Green
       }
       Else{
        $Contains = $false
        Write-Host "The password for user $UserName failed to meet the Domain Complexity requirement. Make sure that the password contains at least one of the following:" `n`n"Lower Case Letter."`n"Upper Case Letter."`n"A Number."`n"Special Character (!,@,#,%,^,&,$,_,-)." -ForegroundColor Red 
            }
 
    If((($forbidden -and $PWDMatch) -eq $false) -and ($Length -and $Contains) -eq $true ){
        $LengthReq = "Yes"
        $forbiddenpass = "No"
        $Meets = "Yes"
        $Change = "Yes"
        $UserMatch = "No"
        $Includes = "Yes"
    }
    If(($Forbidden -eq $false) -and ($Length -eq $false) -and ($PWDMatch -eq $false) -and ($Contains -eq $true)){
        $LengthReq = "No"
        $forbiddenpass = "No"
        $Meets = "No"
        $UserMatch = "No"
        $Change = "Yes"
        $Includes = "Yes"
    }
    If(($Forbidden -eq $false) -and ($Length -eq $false) -and ($PWDMatch -eq $false) -and ($Contains -eq $false)){
        $LengthReq = "No"
        $forbiddenpass = "No"
        $Meets = "No"
        $UserMatch = "No"
        $Change = "Yes"
        $Includes = "No"
    }
    If(($Forbidden -eq $false) -and ($Length -eq $false) -and ($PWDMatch -eq $true) -and ($Contains -eq $true)){
        $LengthReq = "No"
        $forbiddenpass = "No"
        $Meets = "No"
        $UserMatch = "Yes"
        $Change = "Yes"
        $Includes = "Yes"
    }
    If(($Forbidden -eq $false) -and ($Length -eq $true) -and ($PWDMatch -eq $true) -and ($Contains -eq $true)){
        $LengthReq = "Yes"
        $forbiddenpass = "No"
        $Meets = "No"
        $UserMatch = "Yes"
        $Change = "Yes"
        $Includes = "Yes"
    }
    If(($Forbidden -eq $true) -and ($Length -eq $true) -and ($PWDMatch -eq $true) -and ($Contains -eq $true)){
        $LengthReq = "Yes"
        $forbiddenpass = "Yes"
        $Meets = "No"
        $UserMatch = "Yes"
        $Change = "Yes"
        $Includes = "Yes"
    }
    If(($Forbidden -eq $false) -and ($Length -eq $true) -and ($PWDMatch -eq $false) -and ($Contains -eq $true)){
        $LengthReq = "Yes"
        $forbiddenpass = "No"
        $Meets = "Yes"
        $UserMatch = "No"
        $Change = "No"
        $Includes = "Yes"
    }
    $Status += New-Object -TypeName psobject -Property (@{IncludesSpecialCharacters=$Includes;UserName=$UserName;MeetsMinimumLengthRequirement=$LengthReq;PasswordChangeRequired=$Change;MeetsPasswordRequirement=$Meets;ContainsForbiddenPassword=$forbiddenpass;PwdMatchesUserName=$UserMatch})

    }
$date = Get-Date -Format MMddyy
$dirpath = (Set-Path).SelectedPath
$RptName = Read-Host "Enter the name of the file (Example: Report)"
$ReportName = $RptName + '-' + $date + '.csv'
$ReportPath = $dirpath + '\' + $ReportName
$Status|Select-Object -Property UserName,MeetsMinimumLengthRequirement,IncludesSpecialCharacters,MeetsPasswordRequirement,PwdMatchesUserName,ContainsForbiddenPassword,PasswordChangeRequired |Export-Csv -Path $ReportPath -Append -NoTypeInformation
