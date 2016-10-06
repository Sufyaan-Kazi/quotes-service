#!/bin/sh
. $APPNAME/ci/scripts/common.sh

main()
{
  createVarsBasedOnVersion
  echo_msg "Starting assemble for ${APPNAME} at version: ${VERSION}"
  cd $APPNAME
  ./gradlew clean assemble manifestFilter -P buildversion=$VERSION --no-daemon
  cp build/libs/*.jar ../build
  cat build/manifest.yml | s/libs\///g > ../build/manifest.yml
  cat ../build/manifest.yml
  ls ../build
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
export TERM=${TERM:-dumb}
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
