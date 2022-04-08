# clientmigration-project-March-2022
Client AD Migration and Consolidation Project
There are two Scripts (Get-ADComputer-Details.ps1 and Get-ADUser-Details) and three mandatory csv files:
COMPANY-AD-DOMAIN.csv, COMPANYAD-HOST-LIST.csv, and COMPANYAD-USER-LIST.csv
Change the Company in the file name to name of company the project is being run
Change Domain csv file entry in the csv to fqdn of the Domain Controller hosting the PES 3.1 dll and encryption key
Change the HostName file contents with a list of the HostNames of Computers are to be migrated to new Domain
Change the UserName file contents with list of the UserNames of Users being migrated to new Domain
Run the script
