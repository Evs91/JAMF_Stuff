#!/bin/bash
# this will stop EDR Collector
# This is a modified version of what comes with FortiEDR to only stop EDRCollector to allow an upgrade to be installed via JAMF
# Fill out Script Variable 4 when using this script with the stop service password. 

BRAND_NAME=Fortinet
PRODUCT_NAME=FortiEDR
COLLECTOR_NAME=FortiEDRCollector
INSTDIR=/Applications/${PRODUCT_NAME}.app
COLLECTOR_LAUNCHD_JOB_LABEL=com.fortinet.fortiedr.macos.FortiEDRCollector
COLLECTOR_LAUNCHD_JOB_PLIST_NAME=${COLLECTOR_LAUNCHD_JOB_LABEL}.plist
PKG_IDENTIFIER=com.fortiedr.collector
UPGRADE_PLIST_NAME=com.fortiedr.upgrade.plist
UNINSTALL_PLIST_NAME=com.fortiedr.uninstall.plist
UNINSTALLER_NAME=com.fortiedr.uninstaller
TRAY_NAME=FortiEDRTray
APPLICATION_LAUNCHER_NAME=FortiEDRApplicationLauncher
COLLECTOR_LAUNCHD_JOB_PLIST_PATH=/Library/LaunchDaemons/${COLLECTOR_LAUNCHD_JOB_PLIST_NAME}
CONTROL_APP_NAME=FortiEDRControl.app

TRAY_LAUNCHD_JOB_LABEL=com.fortinet.fortiedr.macos.FortiEDRTray
TRAY_LAUNCHD_JOB_PLIST_NAME=${TRAY_LAUNCHD_JOB_LABEL}.plist
TRAY_LAUNCHD_JOB_PLIST_PATH=/Library/LaunchAgents/${TRAY_LAUNCHD_JOB_PLIST_NAME}

UPGRADE_PLIST_PATH=/Library/LaunchDaemons/${UPGRADE_PLIST_NAME}
TRAY_DIR=/Applications/${TRAY_NAME}.app
DATA_DIR="/Library/Application Support/${PRODUCT_NAME}"
COLLECTOR_PATH=${INSTDIR}/Contents/MacOS/FortiEDRCollector.app/Contents/MacOS/${COLLECTOR_NAME}
CONTROL_APP=${INSTDIR}/Contents/MacOS/${CONTROL_APP_NAME}/Contents/MacOS/FortiEDRControl

NETWORK_EXTENSION_NAME=com.fortinet.fortiedr.macos.SysExt.nefilter
ENDPOINT_EXTENSION_NAME=com.fortinet.fortiedr.macos.SysExt.esclient


TEAM_ID=AH4XFXJ7DK
scriptname=$(basename $0)
SUCCESS_CODE=0
STOP_CANCELED_EXIT_CODE=30
ALREADY_STOPPED_CODE=4

#---------------------------------------------

loggedInUserID() {
    scutil <<< "show State:/Users/ConsoleUser" | 
    awk '/kCGSSessionUserIDKey :/ && ! /loginwindow/ { print $3 }' 
}

log() {
    echo "${scriptname}: $@"
    logger "${scriptname}: $@"
}




function IsServiceWithLaunchdJobLabelLoaded()
{
    local service_launchd_job_labal=$1
    /bin/launchctl list "${service_launchd_job_labal}" &> /dev/null
    return $?
}

function StopCollectorService()
{
    if ! IsServiceWithLaunchdJobLabelLoaded "${COLLECTOR_LAUNCHD_JOB_LABEL}" ; then
        return 0
    fi
    log "attempting to stop collector-service"
    password=$1
    ${COLLECTOR_PATH} --stop -rp:"${password}"
    stopAttemptReturnValue=$?

    if [ $stopAttemptReturnValue -eq ${SUCCESS_CODE} ]; then
        echo "sheduled collector service stop"
    elif [ $stopAttemptReturnValue -eq ${STOP_CANCELED_EXIT_CODE} ]; then
        log "error: collector service stop was cancelled. Aborting FortiEDR uninstall"
        exit $stopAttemptReturnValue
    elif [ $stopAttemptReturnValue -ne ${ALREADY_STOPPED_CODE} ] ; then
        log "error: failed to gracefully stop collector service. code=$stopAttemptReturnValue. Aborting FortiEDR uninstall"
        exit $stopAttemptReturnValue
    fi
}

function main()
{
    # Make sure only root can run our script
    if [[ $EUID -ne 0 ]]; then
    	echo "error: must run as root"
    	exit 1
    fi

    password="$1"
    StopCollectorService $password


    # stop service
    /bin/launchctl asuser $(loggedInUserID) /bin/launchctl stop ${TRAY_LAUNCHD_JOB_LABEL}
    log "collector tray stopped"
    
}
main $4
