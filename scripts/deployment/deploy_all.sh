#!/bin/sh

./deploy_multi.sh "$1" "$2" "SIXT-DEV SIXT-QA"
./deploy_multi.sh "$1" "$2" "SIXT-UAT SIXT-PROD" "--testlevel RunLocalTests"