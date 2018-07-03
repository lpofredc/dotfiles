#!/bin/bash
# createConfig - sets the config files

prgname="MCABBER"

echo -e "\e[1;36mInstalling ... ${prgname} ... configuration files ...\e[0m"
sleep 1

source INSTALL_ALL/config.bash

username=$(echo ${USER})

# Setting Variables
if [[ ${HOSTNAME} == "botis" ]] ; then
    MAREPOPATH="/Users/${username}/Repositories/github.com/hringriin/dotfiles/repo/mcabber"
    MAPATH="/Users/${username}/.mcabber_"
else
    MAREPOPATH="/home/${username}/Repositories/github.com/hringriin/dotfiles/repo/mcabber"
    MAPATH="/home/${username}/.mcabber_"
fi

MAINCFG="mcabberrc"


# Accounts
# Add accounts on demand
accounts=(
    'ccchb'
    'uni'
)

# Expects one parameters
# $1: account
# returns the away_priority of the corresponding hostname
function evalPrioAway()
{
    local retval=

    case ${HOSTNAME} in
        "acheron")
            retval="45"
            ;;
        "botis")
            retval="35"
            ;;
        "hardship")
            retval="0"
            ;;
        "medusa")
            retval="15"
            ;;
        "sgs7")
            retval="5"
            ;;
        "skynd")
            retval="55"
            ;;
        "sorth")
            retval="25"
            ;;
        *"strato"*)
            retval="65"
            ;;
        *)
            retval="0"
            ;;
    esac

    if [[ $1 == "" ]] ; then
        exit 1;
    fi

    echo ${retval}
}

# Expects one parameters
# $1: account
# returns the online_priority of the corresponding hostname
function evalPrioOnline()
{
    local retval=

    case ${HOSTNAME} in
        "acheron")
            retval="50"
            ;;
        "botis")
            retval="40"
            ;;
        "hardship")
            retval="0"
            ;;
        "medusa")
            retval="20"
            ;;
        "sgs7")
            retval="10"
            ;;
        "skynd")
            retval="60"
            ;;
        "sorth")
            retval="30"
            ;;
        *"strato"*)
            retval="70"
            ;;
        *)
            retval="0"
            ;;
    esac

    if [[ $1 == "" ]] ; then
        exit 1;
    fi

    echo ${retval}
}

# checks if the directories are available for each account
# if not, they will be created
# merges the mcabberrc from three sources:
#   1: the mcabberrc in the ${MAREPOPATH}
#   2: the priority generated by this script
#   3: the host-specific mcabberconfig in ${MAREPOPATH}
function mergeConf()
{
    for var in ${accounts[@]}
    do
        if [[ ! ( -d ${MAPATH}${var} ) ]] ; then
            mkdir -m 700 ${MAPATH}${var}
            mkdir -m 700 ${MAPATH}${var}/logs
            mkdir -m 700 ${MAPATH}${var}/otr
        else
            if [[ ! ( -d ${MAPATH}${var}/logs ) ]] ; then
                mkdir -m 700 ~/.mcabber_uni/logs
            fi

            if [[ ! ( -d ${MAPATH}${var}/otr ) ]] ; then
                mkdir -m 700 ${MAPATH}${var}/otr
            fi

            if [[ ! ( -d ${MAPATH}${var}/event_files ) ]] ; then
                mkdir -m 700 ${MAPATH}${var}/event_files
            fi
        fi

        cp -ifv ${MAREPOPATH}/mcabberrc ${MAPATH}${var}/mcabberrc

        echo -e "\n# Priority" >> ${MAPATH}${var}/mcabberrc
        echo "set priority = $(evalPrioOnline ${var})" >> ${MAPATH}${var}/mcabberrc
        echo "set priority_away = $(evalPrioAway ${var})" >> ${MAPATH}${var}/mcabberrc

        echo -e "\n# Resource" >> ${MAPATH}${var}/mcabberrc

        if [[ ${HOSTNAME} == *"strato"* ]] ; then
            echo -e "set resource = mcabber_MAIN_$(uname -s)\n" >> ${MAPATH}${var}/mcabberrc
        else
            echo -e "set resource = mcabber_${HOSTNAME}_$(uname -s)\n" >> ${MAPATH}${var}/mcabberrc
        fi

        cat ${MAREPOPATH}/mcabberrc_${var} >> ${MAPATH}${var}/mcabberrc

    done
}

mergeConf
