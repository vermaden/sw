#!/bin/sh
set -e

# usage:
#   sw
#     - start stopwatch from 0 and save start time
#   sw [ -r | --resume ]
#     - start stopwatch from last saved start time (or current time if no saved start time exists)

finish() {
  # restore cursor
  tput cnorm
  exit 0
}

trap finish EXIT

# use GNU date(1) if possible as it has nanoseconds support
if hash gdate 2> /dev/null
then
  GNU_DATE=gdate
fi

__datef() {
  if [ -z "${GNU_DATE}" ]
  then
    date "${@}"
  else
    ${GNU_DATE} "${@}"
  fi
}

# display nanoseconds only if supported
if __datef +%N | grep -q N 2> /dev/null
then
  echo "INFO: install 'sysutils/coreutils' for nanoseconds support"
  DATE_FORMAT="+%H:%M:%S"
else
  DATE_FORMAT="+%H:%M:%S.%N"
  NANOS_SUPPORTED=true
fi

# hide cursor
tput civis

# If '-r/--resume' is passed - use saved start time from ~/.sw file
if [ "${1}" = "-r" -o "${1}" = "--resume" ]
then
  if [ ! -f ~/.sw ]
  then
    gdate +%s > ~/.sw
  fi
  START_TIME=$( cat ~/.sw )
else
  START_TIME=$( __datef +%s )
  echo -n ${START_TIME} > ~/.sw
fi

# GNU date accepts input date differently than BSD
if [ -z "${GNU_DATE}" ]
then
  DATE_INPUT="-v-${START_TIME}S"
else
  DATE_INPUT="--date now-${START_TIME}sec"
fi

while true
do
  STOPWATCH=$( TZ=UTC __datef ${DATE_INPUT} ${DATE_FORMAT} | ( [ "${NANOS_SUPPORTED}" ] && sed 's/.\{7\}$//' || cat ) )
  printf "\r%s" ${STOPWATCH}
  sleep 0.03
done

