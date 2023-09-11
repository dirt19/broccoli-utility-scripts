# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
##TODO
$Networkpath = "<network path>"
#If (Test-Path -Path $Networkpath) {
#    Write-Host "Drive Exists already"
#}
#Else {
#    #map network drive
#    (New-Object -ComObject WScript.Network).MapNetworkDrive("K:","\\<local network ip>\<network path>")
#	New-PsDrive W -Root \\<local network ip>\<network path> -Credential
#
#check mapping again
If (Test-Path -Path $Networkpath) {
    Write-Host "$Networkpath is mapped"
}
Else {
    Write-Host "$Networkpath is not mapped"
}
#}
# Fucntion to take list of directories and any exclusions

## Path to robocopy logfile
$LOGFILE = "C:\portable\backup\logs\"
$USERDIR = "C:\Users\<network path>\"
$DESTDIR = "<network drive>:\backups\<machine-name-backup>\"

## Log events from the script to this location
$SCRIPTLOG = $LOGSDIR + "scriptlog.log"

## Mirror a direcotory tree
$WHAT = @("/MIR")
## /COPY:DATS: Copy Data, Attributes, Timestamps, Security
## /SECFIX : FIX file SECurity on all files, even skipped files.

## This will create a timestamp like yyyymmdd
$TIMESTAMP = get-date -uformat "%Y%m%d"

## Append to robocopy logfile with timestamp
$ROBOCOPYLOG = "/LOG:$LOGFILE`Robocopy`-$TIMESTAMP.log"
$APPENDLOG = "/LOG+:$LOGFILE`Robocopy`-$TIMESTAMP.log"

$SOURCE = $USERDIR + 'Documents'
$DESTINATION = $DESTDIR + 'Documents'
$IGNORE = @(
    "C:\Users\<USER>\Documents\<PATH>\.git\",
    "C:\Users\<USER>\Documents\<PATH>\.git\",
    "C:\Users\<USER>\Documents\<PATH>\.git\"
)
$OPTIONS = @("/R:2","/W:30","/XD" + $IGNORE)
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = $USERDIR + 'Desktop'
$DESTINATION = $DESTDIR + 'Desktop'
$OPTIONS = @("/R:2","/W:30")
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = $USERDIR + 'Downloads'
$DESTINATION = $DESTDIR + 'Downloads'
$OPTIONS = @("/R:2","/W:30")
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = $USERDIR + 'Pictures'
$DESTINATION = $DESTDIR + 'Pictures'
$OPTIONS = @("/R:2","/W:30")
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = $USERDIR + 'Videos'
$DESTINATION = $DESTDIR + 'Videos'
$OPTIONS = @("/R:2","/W:30")
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = $USERDIR + '.ssh'
$DESTINATION = $DESTDIR + '.ssh'
$OPTIONS = @("/R:2","/W:30")
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

$SOURCE = 'C:\portable\'
$DESTINATION = $DESTDIR + 'portable'
$IGNORE = @(
  $LOGFILE
)
$OPTIONS = @("/R:2","/W:30","/XD" + $IGNORE)
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$APPENDLOG,$OPTIONS)
& C:\Windows\System32\Robocopy.exe @cmdArgs

Copy-Item "$USERDIR`.bashrc` " "$DESTDIR`.bashrc` "
Copy-Item "$USERDIR`.gitconfig` " "$DESTDIR`.bashrc` "