#!/bin/bash
#########################################################################
# James Hipp
# System Support Engineer
# Ready Computing
#
# Main Bash script for Cache Performance Monitoring
#
# This script assumes that the user running the script has OS
# Auth enabled into Cache instance(s) and is %All role
#
# Our system OS use-case will be RHEL 7+ (or CentOS 7+)
#
# Usage = cache_perf_mon.sh <command>
#
# Ex: ./cache_perf_mon.sh --cache-info"
# Ex: ./cache_perf_mon.sh --show-app-errors USER"
# Ex: ./cache_perf_mon.sh --show-log"
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
INPUT_COMMAND3=$3

cache_info()
{

   # Display Info About Cache

   # Load Instances into an Array, in case we have Multiple
   instances=()
   while IFS= read -r line; do
      instances+=( "$line" )
   done < <( /usr/bin/ccontrol list |grep Configuration |awk '{ print $2 }' |tr -d "'" )

   for i in ${instances[@]};
   do
      echo ""
      echo "------------------------------"
      echo "Cache Info for $i:"
      echo ""
      echo -e "w ##class(%SYSTEM.Version).GetVersion()\nh" |/usr/bin/csession $i -U %SYS |awk NR==5
      echo ""

      ### ISC Product: Cache = 1, Ensemble = 2, HealthShare = 3
      product=`echo -e "w ##class(%SYSTEM.Version).GetISCProduct()\nh" |/usr/bin/csession $i -U %SYS |awk NR==5`
      case $product in
         1)
            echo "Installed ISC Product = Cache"
            ;;
         2)
            echo "Installed ISC Product = Ensemble"
         ;;
         3)
            echo "Installed ISC Product = HealthShare"
         ;;
         *)
            echo "Unable to Fetch Installed ISC Product Number"
      esac

      echo ""

   done

}

help_text()
{

   # Print Help Text
   echo "----------------------"
   echo "cache_perf_mon.sh"
   echo "----------------------"
   echo ""
   echo "Usage:"
   echo "cache_perf_mon.sh <command(s)>, ..."
   echo ""
   echo "Commands:"
   echo "--cache-info = Display version and ISC product information for Cache"
   echo "--help = Show help notes for this script"
   echo "--show-app-errors <namespace> = List application errors for a namespace"
   echo "--show-log = Show console log warnings and errors"
   echo "--status = Show status of all instances on this machine"
   echo "--version = Print out script version"
   echo ""
   echo "Examples:"
   echo "./cache_perf_mon.sh --cache-info"
   echo "./cache_perf_mon.sh --show-app-errors USER"
   echo "./cache_perf_mon.sh --show-log"
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

show_app_errors()
{

   # Show Application Errors for a Namespace

   echo ""
   echo "Fetching Application Errors for Namespace"
   echo ""
   echo "(If you did not provide a namespace, it will be list from default User Namespace)"
   echo ""

   if [ -z "$INPUT_COMMAND2" ]
   then
      echo "Fetching App Error Log for Default User Namespace"

      # Load Instances into an Array, in case we have Multiple
      instances=()
      while IFS= read -r line; do
         instances+=( "$line" )
      done < <( /usr/bin/ccontrol list |grep Configuration |awk '{ print $2 }' |tr -d "'" )

      for i in ${instances[@]};
      do
         echo ""
         echo "------------------------------"
         echo "Listing Default App Error Log for $i:"
         echo ""
         /usr/bin/csession $i "^%ERN"
         echo ""
      done

   else
      echo "Fetching App Error Log for Namespace $INPUT_COMMAND2"

      # Load Instances into an Array, in case we have Multiple
      instances=()
      while IFS= read -r line; do
         instances+=( "$line" )
      done < <( /usr/bin/ccontrol list |grep Configuration |awk '{ print $2 }' |tr -d "'" )

      for i in ${instances[@]};
      do
         echo ""
         echo "------------------------------"
         echo "Listing App Error in $i for Namespace $INPUT_COMMAND2:"
         echo ""
         /usr/bin/csession $i -U $INPUT_COMMAND2 "^%ERN"
         echo ""
      done

   fi

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
         --cache-info)
            cache_info
            ;;
         --help)
            help_text
         ;;
         --show-app-errors)
            show_app_errors
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

