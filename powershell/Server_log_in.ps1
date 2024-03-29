######################################################################
######################## Server log-in script ########################
########################      Verion 1.0      ######################## 
########################    By Aaron Cole     ######################## 
###################################################################### 
#                    Made for ME with tectia ssh                     # 
###################################################################### 
#########  This Script will ssh into servers by using a list ######### 
######### of server names in a supplied txt document or the  ######### 
######### excel spreadsheet that is maintained and contains  ######### 
#########       all the current server names.   Enjoy!       ######### 
######################################################################
######################################################################
#Global Vars
$prog = "sshg3.exe"
$progargs = "hostname"
$sshcommand = "$prog $server $sshargs"
$outfile = ".\done.txt"

#####################################################################

Function ExcelFile {
$response = "Y"
do {

$File = "D:\My Documents\serverlist.xlsx"
#$File = ".\nowhere.xlsx" #For Debug Purposes
$WS = "Hardware"
$ColumnNumber = 1
$optRow = 3

#Prompt
$title = "Use this $File"
$message = "Are you sure"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Continue"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Input New file"
$MM = New-Object System.Management.Automation.Host.ChoiceDescription "&MM","Go Back to Main Menu"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $MM)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
switch ($result)
    {
        2 {return}
        1 {Write-Host "File must be an excel spreadsheet (.xlsx)"
           $File = Read-Host "Enter the complete file path and name (use .\ if in same directory as script)"
           $WS = Read-Host "Enter the Complete Name of the Worksheet"  
           $ColumnNumber = Read-Host "Enter the Column Number of the server names"
           $optRow = Read-Host "Enter the Row Number to start on"
           Write-Host "Using $File"
           $response = "No"
           }  
        0 {Write-Host "Using $File"
           $response = "No"
           }
        
    } #End of Switch
} #End of Do
while ($response -eq "Y")

#Test if file exists/accessible
 if (Test-Path $File) {
#Test of .xlsx file
    if (dir $File| ? {$_.Extension -eq ".xlsx"} ) {
#If old outfile exists delete it
if (Test-Path $outfile){
	Remove-Item $outfile
}

#Excel Open and Read
    $SystemArray = @()
    $objExcel = New-Object -ComObject Excel.Application
    $objExcel.Visible = $false
    $objExcel.DisplayAlerts = $false
    $WorkBook = $objExcel.Workbooks.Open($File)
    $WorkSheet = $WorkBook.Sheets.Item("$WS")
    $intRowMax = ($WorkSheet.UsedRange.Rows).count
    

#Start on Row ? and keep going while adding 1
#Until it reaches the last row
    for ($intRow = [int]$optRow ; $intRow -le $intRowMax ; $intRow++)
     {
      $system = $WorkSheet.cells.item($intRow,[int]$ColumnNumber).value2

#If cell is not null        
        if ($system) {
        Write-Host "Attempting to log in to $system"  
        cmd /c $prog $system $progargs >> $outfile 2>$null
        $SystemArray += $system
         }
      }

#Read in the output file
$outfilelist = Get-Content $outfile      

#Compare the original list to the output list
$comparision = Compare-Object -ReferenceObject $SystemArray -DifferenceObject $outfilelist -PassThru

#If it is in the original list and not in the 
#output list (command did not run) then display
#those objects (skip over any blanks found)
Write-Host "The Following is a list of servers unable to log in to from the supplied list" -ForegroundColor Red
$comparision | ForEach-Object {
    if ($($_)) {
      "$($_) was not successfully logged into"
     }
 }
 
#Be nice and cleanup excel and close
    $objExcel.quit()
    }#End of If BLock2
     #Else for 2nd if
    else {
          Write-Host "File does not appear to be a .xlsx file"
          Write-Host "Please try again"
          Write-Host -NoNewLine 'Press any key to continue...';
          $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
          Return
          }
          
 }#If block
 else {
        clear
        Write-Host "$File was not found or is not accessible" -ForegroundColor Red
        Write-Host "Ensure network connectivity and accessability and try again" -ForegroundColor Red
        Write-Host "Exiting............." -ForegroundColor Red
        Write-Host -NoNewLine 'Press any key to continue...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        return
        }
        
exit
cmd /c pause | out-null
} #End of Function
#####################################################################

Function TXTFile {

$response = "Y"
do {

#Read file
Write-Host "File to be used must be a .txt file and have 1 server name per line"
$File = Read-Host "Enter the complete file path and name (use .\ if in same directory as script)"

#Prompt
$title = "Use this $File"
$message = "Are you sure"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Continue"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Input New file"
$MM = New-Object System.Management.Automation.Host.ChoiceDescription "&MM","Go Back to Main Menu"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
switch ($result)
    {
        2 { return }
        1 {}
        0 {$response = "No"} 
    } #End of Switch
} #End of Do Loop
while ($response -eq "Y")

#Test if file exists/accessible
 if (Test-Path $File) {

#Test of .TXT file
    if (dir $File| ? {$_.Extension -eq ".txt"} ) {
            
#If old outfile exists delete it
    if (Test-Path $outfile){
    	Remove-Item $outfile
    }
    
#Get-content of $file    
    $serverlist = get-content $File
#For each servername in $File
    foreach ($system in $serverlist) {

#If the line is not null 
        if ($system) {

#SSH into each system and run hostname
#put the hostname output in a file and do not display errors 
            Write-Host "Attempting to log in to $system"
            cmd /c $prog $system $progargs >> $outfile 2>$null
        }
     }

#Read in the output file
    $outfilelist = Get-Content $outfile

#Compare the original list to the output list
    $comparision = Compare-Object -ReferenceObject $serverlist -DifferenceObject $outfilelist -PassThru

#If it is in the original list and not in the 
#output list (command did not run) then display
#those objects (skip over any blanks found)
    Write-Host ""
    Write-Host "The Following is a list of servers unable to log in to from the supplied list" -ForegroundColor Red

    $comparision | ForEach-Object {
        if ($($_)) {
        "$($_) was not successfully logged into"
        }
    }
    }
#Else for 2nd if
    else {
          Write-Host "File does not appear to be a .txt file"
          Write-Host "Please try again"
          Write-Host -NoNewLine 'Press any key to continue...';
          $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
          Return
          }    
}
#Else for first if
 else {
        clear
        Write-Host "$File was not found or is not accessible" -ForegroundColor Red
        Write-Host "Ensure network connectivity and accessability and try again" -ForegroundColor Red
        Write-Host "Exiting............." -ForegroundColor Red
        Write-Host -NoNewLine 'Press any key to continue...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        return
        }
        
exit

    
cmd /c pause | out-null
} #End of Function

########################################################################################
#Start of Script
$response = "Y"
do {
clear
Write-Host "                                                        #####        " -ForegroundColor Magenta
Write-Host "                                                       #######       " -ForegroundColor Magenta
Write-Host "                                 #                     ##O#O##       " -ForegroundColor Magenta
Write-Host "  ###     ###                   ###                    #VVVVV#       " -ForegroundColor Magenta
Write-Host "   ##      ##                    #                   ##  VVV  ##     " -ForegroundColor Magenta
Write-Host "   ##      ##  ### ####      ###    ##### #####     #          ##    " -ForegroundColor Magenta
Write-Host "   ##      ##   ###    ##   #  ##     ##   ##      #            ##   " -ForegroundColor Magenta
Write-Host "   ##      ##   ##     ##  #   ##       ###        #            ###  " -ForegroundColor Magenta
Write-Host "   ##      ##   ##     ##     ###       ###       QQ#           ##Q  " -ForegroundColor Magenta
Write-Host "   ##      ##   ##     ##    ###       ## ##    QQQQQQ#       #QQQQQQ" -ForegroundColor Magenta
Write-Host "   ###    ###   ##     ##    ### #    ##   ##   QQQQQQQ#     #QQQQQQQ" -ForegroundColor Magenta
Write-Host "    ###### ### ####   ####    ###   ##### #####   QQQQQ#######QQQQQ  " -ForegroundColor Magenta
Write-Host "" 
Write-Host "           /###           /                                    " -ForegroundColor Magenta
Write-Host "          /  ############/                                     " -ForegroundColor Magenta
Write-Host "         /     #########                                       " -ForegroundColor Magenta
Write-Host "         #     /  #                                            " -ForegroundColor Magenta
Write-Host "          ##  /  ##                                            " -ForegroundColor Magenta
Write-Host "             /  ###          /##       /###   ### /### /###    " -ForegroundColor Magenta
Write-Host "            ##   ##         / ###     / ###  / ##/ ###/ /##  / " -ForegroundColor Magenta
Write-Host "            ##   ##        /   ###   /   ###/   ##  ###/ ###/  " -ForegroundColor Magenta
Write-Host "            ##   ##       ##    ### ##    ##    ##   ##   ##   " -ForegroundColor Magenta
Write-Host "            ##   ##       ########  ##    ##    ##   ##   ##   " -ForegroundColor Magenta
Write-Host "             ##  ##       #######   ##    ##    ##   ##   ##   " -ForegroundColor Magenta
Write-Host "              ## #      / ##        ##    ##    ##   ##   ##   " -ForegroundColor Magenta
Write-Host "               ###     /  ####    / ##    /#    ##   ##   ##   " -ForegroundColor Magenta
Write-Host "                ######/    ######/   ####/ ##   ###  ###  ###  " -ForegroundColor Magenta
Write-Host "                  ###       #####     ###   ##   ###  ###  ### " -ForegroundColor Magenta
Write-Host ""
Write-Host "######################################################################" -ForegroundColor Magenta
Write-Host "######################## Server log-in script ########################" -ForegroundColor Magenta
Write-Host "########################      Verion 1.0      ########################" -ForegroundColor Magenta
Write-Host "########################    By Aaron Cole     ########################" -ForegroundColor Magenta
Write-Host "######################################################################" -ForegroundColor Magenta
Write-Host "#                    Made for ME with tectia ssh                     #" -ForegroundColor Magenta
Write-Host "######################################################################" -ForegroundColor Magenta
Write-Host "#########  This Script will ssh into servers by using a list #########" -ForegroundColor Magenta
Write-Host "######### of server names in a supplied txt document or the  #########" -ForegroundColor Magenta
Write-Host "######### excel spreadsheet that is maintained and contains  #########" -ForegroundColor Magenta
Write-Host "#########       all the current server names.   Enjoy!       #########" -ForegroundColor Magenta
Write-Host "######################################################################" -ForegroundColor Magenta

#Prompt for file choice
$Title = "Please Choose an input file"
$Info = "Text file must be server names one per line"
$optExcel = new-Object System.Management.Automation.Host.ChoiceDescription "&Excel File","Use the default spreadsheet template that is used for CRQs/WO on the shared drive"
$optTXT = new-Object System.Management.Automation.Host.ChoiceDescription "&TXT File","Use a Text File of server names one per line"
$optQuit = new-Object System.Management.Automation.Host.ChoiceDescription "&Quit","Exit"
$Choice = [System.Management.Automation.Host.ChoiceDescription[]] @($optExcel,$optTXT,$optQuit)
[int]$defaultchoice = 0
$opt =  $host.UI.PromptForChoice($Title , $Info , $Choice , $defaultchoice)
switch($opt)
    {
        0 { ExcelFile }
        1 { TXTFile }
        2 { Write-Host "Good Bye!!!" -ForegroundColor Green
            exit
            }
    } #End of Switch

} #End of Do Loop

while ($response -eq "Y")
cmd /c pause | out-null