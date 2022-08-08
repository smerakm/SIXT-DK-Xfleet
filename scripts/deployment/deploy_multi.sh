#!/bin/sh

if (( $# < 3 ))
then
        echo “USAGE: $0 \<type of manifest, e.g. -x, -m\> \<metadata defintion, e.g. path to package.xml or CustomField:Vehicle__c.VIN_Number__c\> \<list of targetusernames separated by space\>“
        echo "EXAMPLE: $0 -x ../../manifest/package_ALL.xml \"SIXT-DEV SIXT-QA\""
fi

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White


## declare an array variable
declare -a arr=($3)

## now loop through the above array
for i in "${arr[@]}"
do
   echo "$i"
   # or do whatever with individual element of the array
   echo "${Purple}deploying $2 to ${BCyan}$i${Color_Off}"
   if sfdx force:source:deploy $1 $2 --targetusername $i $4; then
      echo "${BGreen}DONE ($i)!${Color_Off}"
   else
      echo "${BRed}ERROR! ($i)!${Color_Off}"
      exit 1
   fi
done

