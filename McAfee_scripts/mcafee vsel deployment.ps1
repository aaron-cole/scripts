




$cpprog = "scpg3"
$sshprog = "sshg3.exe"

$targets = Get-Content "C:\Users\aaroncole\Downloads\list.txt"
$folders = "C:\Users\aaroncole\Downloads\ePO Software\CM-195602-McAfeeVSEForLinux-1.9.1.29107","C:\Users\aaroncole\Downloads\ePO Software\CM-198866-McAfeeVSEForLinux-1.9.1.29107-HF988521","C:\Users\aaroncole\Downloads\ePO Software\CM-199479-McAfeeVSEForLinux-1.9.1.29107-HF1065267"
$allVSEcmd = "cd /tmp/CM-195602-McAfeeVSEForLinux-1.9.1.29107/McAfeeVSEForLinux-1.9.1.29107/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-release-full.noarch.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-release.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107.noarch.tar.gz; sudo ./McAfeeVSEForLinux-1.9.1.29107-installer; cd /tmp/CM-198866-McAfeeVSEForLinux-1.9.1.29107-HF988521/McAfeeVSEForLinux-1.9.1.29107-HF988521/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF988521-release.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF988521.tar.gz; sudo ./setupHF; cd /tmp/CM-199479-McAfeeVSEForLinux-1.9.1.29107-HF1065267/McAfeeVSEForLinux-1.9.1.29107-HF1065267/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF1065267-release.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF1065267.tar.gz; sudo ./setupHF"
$cleanup = "sudo /etc/init.d/nails start; rm -rf /tmp/CM-19*; sudo /opt/McAfee/cma/bin/cmdagent -P; sudo /opt/McAfee/cma/bin/cmdagent -C" 

 
foreach ($system in $targets) {
  $systemloc = $system + ":/tmp"
  
  #$folders | ForEach-Object {
      #cmd /c start $cpprog -r """$_""" $systemloc}

  cmd /c $sshprog -t $system $allVSEcmd
  cmd /c $sshprog -t $system $cleanup  
 } 
 

 
     #Try 1
 #$targets = Get-Content "C:\Users\aaroncole\Downloads\list.txt"
 #$VSEcmd = "cd /tmp/CM-195602-McAfeeVSEForLinux-1.9.1.29107/McAfeeVSEForLinux-1.9.1.29107/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-release-full.noarch.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-release.tar.gz; sudo ./McAfeeVSEForLinux-1.9.1.29107-installer"
 #$VSEHF1 = "cd /tmp/CM-198866-McAfeeVSEForLinux-1.9.1.29107-HF988521/McAfeeVSEForLinux-1.9.1.29107-HF988521/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF988521-release.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF988521.tar.gz; sudo ./setupHF"
 #$VSEHF2 = "cd /tmp/CM-199479-McAfeeVSEForLinux-1.9.1.29107-HF1065267/McAfeeVSEForLinux-1.9.1.29107-HF1065267/; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF1065267-release.tar.gz; tar xvzf McAfeeVSEForLinux-1.9.1.29107-HF1065267.tar.gz; sudo ./setupHF"
 #$aftercmd = "sudo /etc/init.d/cma restart; sudo /etc/init.d/nails start; sudo /opt/McAfee/cma/bin/cmdagent -C"
 # foreach ($system in $targets) {
     
 #    cmd /c $sshprog -t $system $VSEcmd
 #    cmd /c $sshprog -t $system $VSEHF1
 #    cmd /c $sshprog -t $system $VSEHF2
 #    cmd /c $sshprog -t $system $aftercmd
 #     }