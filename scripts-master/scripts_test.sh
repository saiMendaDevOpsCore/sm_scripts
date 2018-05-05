#!/bin/bash

## Script to test my scripts.
# 1. Creates a google cloud server and run the script and check it

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
#source /root/scripts/common-functions.sh
source /tmp/common-functions.sh

SUMFILE=/tmp/sumfile 
[ ! -s $SUMFILE ] && echo "0" >/tmp/sumfile 

CONFIG=$1 
URL=$2 

curl -s $URL >/tmp/script
SCRIPT=/tmp/script 
OLDSUM=$(cat $SUMFILE)
md5sum $SCRIPT | awk '{print $1}' > $SUMFILE 
NEWSUM=$(cat $SUMFILE)
if [ "$OLDSUM" = "$NEWSUM" ]; then 
    Info "No Changes in script .. Hence skipping"
    exit 0
fi 

Info "Setting Up GCLOUD Account"
gcloud config configurations activate $CONFIG &>/tmp/log

Info "Checking Server running or not"
gcloud compute instances list &>>/tmp/log 
if [ $? -ne 0 ]; then 
    error "Unable to get the vm list. Check Error in /tmp/log"
fi
gcloud compute instances list | grep -w test &>>/tmp/log 
if [ $? -eq 0 ]; then 
    Info "Deleting existing VM"
    gcloud -q compute instances delete test --zone europe-west1-b &>>/tmp/log 
    Stat $? "Deleting VM"
fi 

gcloud compute instances create --image mycentos7 --zone europe-west1-b test  &>>/tmp/log 

PUBLICIP=$(gcloud compute instances list | grep -w test  | awk  '{print $(NF-1)}')
sed -i -e "/$PUBLICIP/ d" ~/.ssh/known_hosts 
i=120
while [ $i -gt 0 ]; do 
    ncat  $PUBLICIP  22 </dev/null &>/dev/null 
    if [ $? -eq 0 ]; then 
        break
    else
        continue
    fi 
    error "SSH Connection Failed -IP : $PUBLICIP"
done

Info "Connecting through SSH to run the script"
scp -i ~/devops.pem -o StrictHostKeyChecking=no  $SCRIPT ec2-user@$PUBLICIP:$SCRIPT &>/dev/null
ssh -i ~/devops.pem -l ec2-user -o StrictHostKeyChecking=no $PUBLICIP "sudo sh $SCRIPT"

