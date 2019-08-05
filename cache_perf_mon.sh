#!/bin/bash
#########################################################################
# James Hipp
# System Support Engineer
# Ready Computing
#
# Script for Cache Performance Monitoring
#
# This script assumes that the user running the script has OS
# Auth enabled into Cache instance(s) and is %All role
#
# Our system OS use-case will be RHEL 7+ (or CentOS 7+)
#
# Usage = cache_perf_mon.sh
# Usage = cache_perf_mon.sh <command>
#
# Ex: ./cache_perf_mon.sh
# Ex: ./cache_perf_mon.sh --help
#
# (See Help Function for Full Usage Notes)
#
#
### CHANGE LOG ###
#
#
#########################################################################

VERSION="1.00"

INPUT_COMMAND1=$1
INPUT_COMMAND2=$2

help_text()
{

   # Print Help Text
   echo "----------------------"
   echo "cache_perf_mon.sh"
   echo "----------------------"
   echo ""
   echo "Usage:"
   echo "cache_perf_mon.sh"
   echo "cache_perf_mon.sh <command>"
   echo ""
   echo "Commands:"
   echo "--help = Show help notes for this script"
   echo "--license = Show license usage and info"
   echo "--show-log = Show log warnings and errors"
   echo "--status = Show status of all instances on this machine"
   echo "--version = Print out script version"
   echo ""
   echo "Examples:"
   echo "./cache_perf_mon.sh"
   echo "./cache_perf_mon.sh --status"
   echo ""

}

is_cache()
{

   ### Check if Cache is Installed ###

   if [ -e "/usr/bin/ccontrol" ]
   then
      return 0
   else
      return 1
   fi

}

is_down()
{

   # Return False if any Instances show Running
   if [ "`/usr/bin/ccontrol list |grep running,`" ]
   then
      return 1
   else
      return 0
   fi

}

is_up()
{

   # Return False if any Instances show down
   if [ "`/usr/bin/ccontrol list |grep down,`" ]
   then
      return 1
   else
      return 0
   fi

}

license_usage()
{

   # Load Instances into an Array, in case we have Multiple
   instances=()
   while IFS= read -r line; do
      instances+=( "$line" )
   done < <( /usr/bin/ccontrol list |grep Configuration |awk '{ print $2 }' |tr -d "'" )

   for i in ${instances[@]};
   do
      echo ""
      echo "------------------------------"
      echo "License Usage for $i:"
      echo ""
      /usr/bin/csession $i "##class(%SYSTEM.License).ShowSummary()"
      echo ""
      echo ""
   done

}

show_log()
{

   echo ""
   echo "Parsing out cconsole.log for Severity Messages Greater Than 1"
   echo ""

   # Load Instances into an Array, in case we have Multiple
   instances=()
   while IFS= read -r line; do
      instances+=( "$line" )
   done < <( /usr/bin/ccontrol list |grep Configuration |awk '{ print $2 }' |tr -d "'" )

   for i in ${instances[@]};
   do
      echo "Log Messages for $i"
      echo ""

      local_installdir=`/usr/bin/ccontrol list $i |grep directory |awk '{ print $2 }'`
      log_file=$local_installdir/mgr/cconsole.log

      cat $log_file |egrep -i "\) 2 | \( 3" |tail -n 20
      echo ""
   done

}

status_text()
{

   # Print List of Instances
   /usr/bin/ccontrol list

}

main ()
{

   if is_cache;
   then

      # Parse out CLI Argument to see what we Need to do
      case $INPUT_COMMAND1 in
         --help)
            help_text
         ;;
         --license)
            license_usage
         ;;
         --show-log)
            show_log
         ;;
         --status)
            echo ""
            echo "--------------------"
            echo "Status of Instances"
            echo "--------------------"
            status_text
            echo ""
         ;;
         --version)
            echo ""
            echo "Script Version = $VERSION"
            echo ""
         ;;
         *)
            echo ""
            echo "$INPUT_COMMAND1 = Not Valid Input"
            echo ""
            help_text
      esac

   else
      echo ""
      echo "Cache is not Installed, ... Exiting"
      echo ""

   fi

}

main

