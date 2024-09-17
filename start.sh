#!/bin/bash

source ./scripts/util.sh

check_commands
check_aws_env

./scripts/manage_ec2.sh start
