#!/bin/sh

./deploy_multi.sh "$1" "SIXT-DEV SIXT-QA"
./deploy_multi.sh "$1" "SIXT-UAT SIXT-PROD" "--testlevel RunLocalTests"