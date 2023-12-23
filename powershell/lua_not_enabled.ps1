#Get registry entry
$regentry = Get-ItemProperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA"

#If value = 0
if($regentry.EnableLUA -eq 0 )

{ #Brackets for the success of if statement

# Execute program with "&"
# Ensure to use single quotes to mitigate spaces
 & 'C:\Users\aaroncole\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories'

} #End bracket for if success

# if you want to do something if not = 0
# Uncomment the following

#else 
# { #This is the start of the if not = to 0
#Do something
# } # This is the end of the if not = to 0