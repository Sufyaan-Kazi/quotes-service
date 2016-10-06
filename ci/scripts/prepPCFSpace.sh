#!/bin/sh 
set -e
. $APPNAME/ci/scripts/common.sh

checkEnvHasSCS(){
  DiscovInstalled=`cf marketplace | grep p-service-registry`
  if [[ -z $DiscovInstalled ]]
  then
    echo "The targeted PCF environment does not have Service Discovery in the marketplace, installation will now halt."
    exit 1
  fi
}

create_single_service()
{
  line="$@"
  SI=`echo "$line" | cut -d " " -f 3`
  EXISTS=`cf services | grep ${SI} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    echo "About to create: $line"
    if [[ $line == *"p-config-server"*  &&  ! -z "$GITHUB_URI" ]]
    then
      #Annoying hack because of quotes, single quotes etc ....
      GIT=`printf '{"git":{"uri":"%s","label":"%s"}}\n' "${GITHUB_URI}" ${GITHUB_BRANCH}`
      cf create-service $line -c ''$GIT''
    elif [[ $line == *"p-mysql"* ]]
    then
      #Yet another annoying hack ....
      PCF_PLAN=`cf marketplace -s p-mysql | grep 100mb | cut -d " " -f1 | xargs`
      cf create-service p-mysql $PCF_PLAN $SI
    else
      cf create-service $line
    fi
    scs_service_created=1
    echo "Created: $line"
  else
    echo_msg "${SI} already exists"
  fi
}

create_all_services()
{
  scs_service_created=0

  # Read all the services that need to be created
  file="$APPNAME/ci/PCFServices.list"
  while IFS= read -r line 
  do
    if [ ! "${line:0:1}" == "#" ]   #Skip comments
    then
      create_single_service "$line" 
    fi
  done < "$file"
  echo_msg "Services created, bear in mind Spring Cloud Services need about a minute to fully initialise."

  if [ $scs_service_created -eq 1 ]
  then
    # Sleep for service registry
    cf service discovery-service | grep Status: | grep "create in progress"
    wc=1
    while [ wc -eq 1 ]
    do
      wc=`cf service discovery-service | grep Status: | grep "create in progress" | wc -l | xargs`
      echo $wc
    done
    cf service discovery-service | grep Status:
  fi
}

main()
{
  cf_login
  summaryOfServices
  checkEnvHasSCS
  create_all_services
  summaryOfServices
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
exit 0
