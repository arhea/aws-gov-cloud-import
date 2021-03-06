#!/bin/bash

######################################################################################################################
#  Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.                                           #
#                                                                                                                    #
#  SPDX-License-Identifier: Apache-2.0                                                                               #
######################################################################################################################

#Test for IAM Role
iamrole_verify(){
IAMROLE=$(aws configure list | awk '/iam/ {print $3}' | head -n 1)
if [[ $IAMROLE != 'iam-role' ]]; then
  echo "fail:iam"
  exit
fi
}

#Passed Variables
while getopts b: OPTION
do
  case "${OPTION}"
  in
  b) BUCKET=$OPTARG;;
  esac
done

s3_mount(){
  MOUNTED_BUCKET=$(ps aux | awk '/home\/ec2-user\/s3fs\/'$BUCKET'/ {print $12}')
  if [[ $MOUNTED_BUCKET != $BUCKET ]]; then
    #Make mount point for s3 bucket
    if [[ -d "/home/ec2-user/s3fs/$BUCKET" ]]; then
      sudo rm -f /home/ec2-user/s3fs/$BUCKET/*
    else
      sudo mkdir /home/ec2-user/s3fs/$BUCKET
    fi
    #Mount
    sudo s3fs $BUCKET /home/ec2-user/s3fs/$BUCKET/ -o iam_role=auto  -o ensure_diskfree=2048 \
    -o parallel_count=15  -o use_cache=/tmp -o allow_other -o readwrite_timeout=180
    PS_AUX=("sudo s3fs $BUCKET /home/ec2-user/s3fs/$BUCKET/ -o iam_role=auto  -o ensure_diskfree=2048 -o parallel_count=5  -o use_cache=/tmp -o allow_other -o readwrite_timeout=180")
  fi
}

s3_verify(){
  #We're trusting that if its a running process, its up...
  MOUNTED_BUCKET=$(ps aux | awk '/home\/ec2-user\/s3fs\/'$BUCKET'/ {print $12}')
  if [[ $MOUNTED_BUCKET == $BUCKET ]]; then
    STATE="mounted"
    #Response to Node
    echo "success"
  else
    echo "fail"
  fi
}

s3_mount
s3_verify
