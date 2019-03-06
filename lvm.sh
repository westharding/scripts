#!/usr/bin/bash

# ABOUT THIS SCRIPT:
# THIS SCRIPT IS ABOUT LEARNING LVMS ON REDHAT/CENTOS 7.0.
# THE OPERATION WILL BE DONE STEP BY STEP, INTERACTING WITH YOU.
# WHEN YOU SEE THE PROMPT "# " THEN YOU CAN PRESS ENTER TO
# CONTINUE THE OPERATIONS.


# DEFINED VARIABLES
b=$(tput smso)
n=$(tput rmso)



# DEFINED FUNCTIONS

# FUNCTION TO PAUSE AND GET PERMISSION TO CONTINUE
# ################################################
function pause (){
if [ -z "$1" ]; then printf '# '; read x
else echo ; echo "$1"; printf '# '; read x
fi

}

# THE THREE BELOW FUCTIONS ARE DEPENDENT AND PROMPT USER
# FOR AN ACTION, PROVIDING A LIST OF AVAILABLE OPERATIONS 
# #######################################################
 
function runit () {

com=$1
prev=$2

COLUMNS=$(tput cols)
printf %"$COLUMNS"s |tr " " "|"
echo ; echo; echo " COMMAND TO RUN ->  ${b}${com}${n}"; echo
echo " [p]previous command: $prev"
echo " [q]quit    [r]restart    [s]skip    [Enter]run?"
printf %"$COLUMNS"s |tr " " "|"
printf "# " ; read confirmation

if [[ $confirmation =~ 'q' ]]; then exit 0;
   elif [[ $confirmation =~ 'r' ]]; then ./$(basename "$0") && exit
   elif [[ $confirmation =~ 's' ]]; then echo 
   elif [[ $confirmation =~ 'p' ]]; then 
      if [ -z "${prev}" ] ; then 
            echo 'No previous command exists!' ; sleep 2
         else 
            rerun "${prev}" "${com}"
      fi
   else
      clear
      echo "# ${com}" 
      sleep 1
      /bin/bash -c "${com}"
      printf "# " ; read x
      #pause "# "
fi
}


function rerun() {

clear
cmnd=$1
nx=$2
echo ; echo " PREVIOUS COMMAND ->  ${b}$cmnd${n}"
echo; echo " [r]Restart | [q]Quit | [s]Skip | [Enter]Run?"; echo
printf "# " ; read confirmation

if [[ $confirmation =~ 'q' ]]; then exit 0;
   elif [[ $confirmation =~ 'r' ]]; then ./$(basename "$0") && exit
   elif [[ $confirmation =~ 's' ]]; then printf "# "
   else
      clear
      echo "# ${cmnd}" 
      sleep 1
      /bin/bash -c "${cmnd}"
      sleep 1
      finrun "${nx}"
fi
}


function finrun() {

com=$1
COLUMNS=$(tput cols)
echo
echo ' RETURNING BACK FROM PREVIOUS COMMAND ...'
echo " COMMAND TO RUN ->  ${b}${com}${n}"; echo
echo " [q]quit    [r]restart    [s]skip    [Enter]run?"
echo
printf "# " ; read confirmation

if [[ $confirmation =~ 'q' ]]; then exit 0;
   elif [[ $confirmation =~ 'r' ]]; then ./$(basename "$0") && exit
   elif [[ $confirmation =~ 's' ]]; then printf "# "
   else
      clear
      echo "# ${com}" 
      sleep 1
      /bin/bash -c "${com}"
      printf "# " ; read x
fi
}



# STARTING MAIN CODE
#

# First provide some informatn from disk geometry to user

clear; echo;echo " ${b} LVMS ON REDHAT/CENTOS 7.0 ${n}"
cat <<EOF

 ┌─────────────────────────────────────────────┐
 │ Disk geometry information on current server │
 └─────────────────────────────────────────────┘

 You have the following disk partitions:

$(fdisk -l | grep Disk | grep dev | awk -F ":" '{print $1}' | sed -e 's/Disk //g')
 
 To see the information about the size of the disk,
 you can use the following commands:

  - Option 1:
  # lsblk | grep -Ei "disk|part"

  - Option 2:
  # fdisk -l | grep Disk | grep dev 

  - Option 3:
  # vgdisplay | grep PE
  
  Note:
  Option 1 is giving more accurate size estimate,
  rather than other options.

  In following both options will be prompt to run and 
  you can compare the results.
   
EOF
echo

cmd1="lsblk|grep -Ei \"disk|part\""
cmd2="echo;echo"
cmd3="fdisk -l|grep Disk|grep dev"
cmd4="vgdisplay|grep PE"
runit "$cmd1 && $cmd2 && $cmd3 && $cmd2 && $cmd4"


clear; cat <<EOF

 ┌──────────────────────────┐
 │ Checking Free Disk Space │
 └──────────────────────────┘
 
 A quick way to see how much disk space is available for a new 
 partition is to create a partition using fdisk command and then
 exit from fdisk program without saving information onto the disk.
 (Do not use command 'w').
 
 We run fdisk and type command 'n' (new partition) for the first
 prompt, then accept default value for all the following prompts 
 coming after by pressing enter.

 On the output of last prompt you will see the real available size 
 for creating a new disk.

 Now here in following select the the disk and then script will 
 simulate running fdisk and creates a new partition without saving
 the operation:

EOF


disks=($(lsblk | grep disk | awk '{print $1}'))
options=($disks "quit")
PS3="Your choice: "

select dsk in "${options[@]}"
do
   case $dsk in
       vd*|sd*)
          
          echo ┌───────────────────────────────────────────┐
          echo "  Partition inforamtion for disk: /dev/$dsk"
          echo └───────────────────────────────────────────┘
 
          fdisk /dev/$dsk <<EOF
          n
          
          
          
          
         
          q          
EOF
pause
clear; cat <<EOF
 
 ┌────────────────────┐
 │ New Partition Size │
 └────────────────────┘

 Note:
 partition name: /dev/$dsk 
 
 Now provide the size required for new LVM linux partition. 
 size examples: 
 +400M 
 +2G 
 +1.5G (Not accepted, has to be integer) 
 +1024000K

EOF
          read -p  ' Size: ' size
          clear
          echo;echo "${b} fdisk created new Linux LVM with the following result: ${n} ";echo
          fdisk /dev/$dsk <<EOF
          n
          
         
           
          $size
          t
          
          8e
          p
          w
EOF
pause

clear; cat <<EOF

 ┌─────────────────────────────┐
 │ Creating Partition by fdisk │
 └─────────────────────────────┘

 The below command:
 fdisk /dev/$dsk

  - has created a partition with the size of $size via command 'n' and
  - type of 8e (Linux LVM), via command 't'.

 
 The new partition layout is as following:

"$(fdisk -l | egrep ^\\/dev\\/)"

 Note
 ~~~~ 
 In order to make this change be noticed by operating system, we use
 command partprobe to inform the OS of partition table changes.

EOF

runit 'partprobe'



newdisk=$(fdisk -l | egrep \^\\\/dev\\\/ | tail -1 | awk '{print $1}')
clear; cat <<EOF

 ┌───────────────────────┐
 │ Creating Volume Group │
 └───────────────────────┘
 
 Note:
 partition name or physical volume name: $newdisk
 partition size: $size

 Now it is time to create a volume group based on the 
 available new created partition.

 
 Size option format from vgcreate man page:
  
 -s, --physicalextentsize PhysicalExtentSize[bBsSkKmMgGtTpPeE]
     Sets  the  physical extent size on physical volumes of this volume group.
     A size suffix (k for kilobytes up to t for terabytes) is optional, 
     megabytes is the default if no suffix is present. 
     The value must be at  least  1  sector  for LVM2  format  
     (where the sector size is the largest sector size of the PVs currently used in the VG) 
     or 8KiB for LVM1 format and it must be a power of 2. The default is 4 MiB.

 
 Now you provide a name and size of new volume group.
 
EOF
          read -p ' Volume group name: ' volgrp
          read -p ' Volume Size: ' volsize
          cmd="vgcreate -s $volsize $volgrp $newdisk"
          runit "${cmd}"
          vgdisplay $volgrp

clear; cat <<EOF

 ┌─────────────────────────┐
 │ Creating Logical Volume │
 └─────────────────────────┘
 
 Note:
 partition name: $newdisk
 partition size: $size 
 volume group name: $volgrp
 volume group size: $volsize
         
 After creating volume group $volgrp then we create a new logical volume
 on that volume group.

 So we provide a name and a size for the logical volum.
  
 -L, --size LogicalVolumeSize[bBsSkKmMgGtTpPeE]
 
 Examples of volume size:
 100M
 2048K
 2G
 

EOF


   read -p ' Logical volume name: ' lvname
   read -p ' Logical volume size: ' lvsize
   cmd="lvcreate -n /dev/$volgrp/$lvname -L $lvsize $volgrp"
   runit "${cmd}"
   cmd="lvdisplay /dev/$volgrp/$lvname"
   runit "${cmd}"

clear; cat <<EOF
 
 ┌───────────────────────────────┐
 │ Formatting The Logical Volume │
 └───────────────────────────────┘
 
 Note:
 partition name: $newdisk
 partition size: $size 
 volume group name: $volgrp
 volume group size: $volsize
 logical volume name: $lvname
 logical volume size: $lvsize

 Lets format the new logical volume $lvname

EOF

   cmd="mkfs.xfs /dev/$volgrp/$lvname"
   runit "${cmd}"



          break
          ;;
       quit)
          exit 0 
          break
          ;;          
       *)
            echo "You didn't choose any disk!"
  esac
done

pause 'Reverting operations!' 

lvremove -f /dev/$lvdsk/$lvname &>/dev/null
vgremove -f $volgrp &>/dev/null
fdisk /dev/$dsk <<EOF &>/dev/null
d

w
EOF
partprobe &>/dev/null

echo
echo OPERATION COMPLETED!
echo