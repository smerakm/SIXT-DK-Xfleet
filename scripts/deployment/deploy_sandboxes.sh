#!/bin/sh

#sfdx force:source:deploy $1 --targetusername SIXT-DEV
#sfdx force:source:deploy $1 --targetusername SIXT-QA
#sfdx force:source:deploy $1 --targetusername SIXT-UAT

./deploy_multi.sh "$1" "SIXT-DEV SIXT-QA SIXT-UAT"