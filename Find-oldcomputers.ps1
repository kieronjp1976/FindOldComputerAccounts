#Script to find Windows computer accounts that can potentially be deleted, it then gets the date that the password was last set giving an indication of how long it has been offline.
# Output to CSV file  OldComputerObjects.csv
#Kieron Palmer
#
#4 Dec 2019
###################################################################################################

# setup output file
$ErrorLog = ".\OldComputerObjects.csv"
$log=Get-Item $ErrorLog -ErrorAction SilentlyContinue
if($Log)
{
Write-host "removing old log file"
Remove-Item $ErrorLog
}
$headers = "Name,Month (Password),Year (Password), Error"
out-file -FilePath $ErrorLog -InputObject $headers -Append

#Get windows virtual and physical servers based on naming convention, this could be made smarter eg. AD attributes
$servers= (Get-ADComputer -Filter * | where {$_.name -match "WV" -or $_.name -match "WP" }).name  # Search AD for specific machines

function Get-Password  #called later in script
{
$ldap="(name=$server)"
        $PasswordDate= Get-ADComputer -ldapfilter $ldap -Properties PasswordLastSet
        $outstring= $server + "," + ($PasswordDate.passwordlastset).month + "," + ($PasswordDate.passwordlastset).year + "," + $ErrMsg
        out-file -FilePath $ErrorLog -InputObject $outstring -Append
}


foreach ($server in $servers)
{
    #Is server in DNS?
    try
    {
    $a=Resolve-DnsName $server -ErrorAction stop
    }


    #Catch DNS error, this isnt very specific - make it more so
    catch [System.ComponentModel.Win32Exception]{

            Write-host $server " is not in DNS" -ForegroundColor Red
            $ErrMsg="DNS"
            Get-Password 
            continue
            }
#catch all
catch {write-host "An error has occurred"}

# For servers that are in DNS, see if they ping
$ping=Test-NetConnection -ComputerName $server -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if ($ping.pingsucceeded -eq $false)
    {
    Write-Host $server " does not respond to ping"
    $ErrMsg="Ping"
    Get-Password 
    }

}

