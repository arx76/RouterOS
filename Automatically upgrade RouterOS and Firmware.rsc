########################################################################################
##   Automatically upgrade RouterOS and Firmware
##   https://github.com/massimo-filippi/mikrotik
##
##   script by Maxim Krusina, maxim@mfcc.cz
##   based on: http://wiki.mikrotik.com/wiki/Manual:Upgrading_RouterOS
##   created: 2014-12-05
##   updated: 2015-12-09
##   tested on: RouterOS 6.33.1 / multiple HW devices, won't work on 6.27 and older (different update process & value naming)
########################################################################################

########## Set variables

## Notification e-mail
:local email "xyz@xyz.com"
# MAIL SMTP DYNAMIC Config Section, Make sure to change these values to match your's / Jz
:local webmailid "xyz@xyz.com"
:local webmailuser "xyz@xyz.com"
:local fromuser "xyz@xyz.com"
:local webmailpwd "mail-password"
:local webmailport "465"
:local webmailsmtp
:set webmailsmtp [:resolve "smtp address"];

# Setting gmail options in tool email as well, useful when u dont have configured toosl email option
/tool e-mail set address=$webmailsmtp port=$webmailport start-tls=tls-only from=$webmailid user=$webmailuser password=$webmailpwd

########## Do the stuff
## Check for update
/system package update
set channel=current
check-for-updates

## Waint on slow connections
:delay 15s;

## Important note: "installed-version" was "current-version" on older Roter OSes
:if ([get installed-version] != [get latest-version]) do={ 

   ## New version of RouterOS available, let's upgrade
   /tool e-mail send to="$email" subject="Upgrading RouterOS on router $[/system identity get name]" body="Upgrading RouterOS on router $[/system identity get name] from $[/system package update get installed-version] to $[/system package update get latest-version] (channel:$[/system package update get channel])"
   :log warning  ("Upgrading RouterOS on router $[/system identity get name] from $[/system package update get installed-version] to $[/system package update get latest-version] (channel:$[/system package update get channel])")     
   ## Wait for mail to be send & upgrade
   :delay 15s;
   
   ## "install" command is reincarnation of the "upgrade" command - doing exactly the same but under a different name
   install
} else={
   ## RouterOS latest, let's check for updated firmware
    :log warning  ("No RouterOS upgrade found, checking for HW upgrade...")

   /system routerboard
   :if ( [get current-firmware] != [get upgrade-firmware]) do={ 
      ## New version of firmware available, let's upgrade
      /tool e-mail send to="$email" subject="Upgrading firmware on router $[/system identity get name]" body="Upgrading firmware on router $[/system identity get name] from $[/system routerboard get current-firmware] to $[/system routerboard get upgrade-firmware]"
      :log warning  ("Upgrading firmware on router $[/system identity get name] from $[/system routerboard get current-firmware] to $[/system routerboard get upgrade-firmware]")
      
      ## Wait for mail to be send & upgrade
      :delay 15s;
      upgrade

      ## Wait for upgrade, then reboot
      :delay 180s;
      /system reboot
   } else={
   :log warning  ("No Router HW upgrade found")
   }
}