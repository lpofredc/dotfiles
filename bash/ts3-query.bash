#!/bin/bash
# ts3-query

# config - tmp files
tmpDir="/tmp"
tmp1="tmp01_$$"
tmp2="tmp02_$$"
tmp3="tmp03_$$"
tmp4="tmp04_$$"
tmp5="tmp05_$$"
tmp6="tmp06_$$"
tmp7="tmp07_$$"
tmp8="tmp08_$$"
tmp9="tmp09_$$"
tmp10="tmp10_$$"
tmp11="tmp11_$$"
onlinetimes="oltimes$$"
clientDataDir="cldata$$"
serverDataDir="srdata$$"
clientnames="clnames$$"
clplatform="clplatform$$"
clcountry="clcountry$$"
clversion="clversion$$"
srvVersion="srvVersion$$"
srvPlatform="srvPlatform$$"
srvUptime="srvUptime$$"
srvPing="srvPing$$"
srvGrpList="srvGrpList$$"
grpIDs="grpIDs$$"
awaystatus="awaystatus$$"

# config - ts3 query user data
username=""
passphrase=""

# config - ts3 query server data
server="niederhoelle.de"
port="10011"

# config - webserver
serverDir="/var/www/ts3-query/data"

# "Things" that need to be done before the script can work
function preceedings ()
{
    # if /tmp is not existing ... PANIC :-)
    if [[ ! ( -d ${tmpDir} ) ]] ; then
        exit 10
    fi

    # create dir where to save all client's information, one file per client
    mkdir -p ${tmpDir}/${clientDataDir}

    # double check client's information exist, if not ... PANIC AGAIN :-)
    if [[ ! ( -d ${tmpDir}/${clientDataDir} ) ]] ; then
        exit 11
    fi

    # create dir where to save all server's information
    mkdir -p ${tmpDir}/${serverDataDir}

    # double check server's information exist, if not ... PANIC AGAIN :-)
    if [[ ! ( -d ${tmpDir}/${serverDataDir} ) ]] ; then
        exit 12
    fi
}

# telnet foo
# connect to server with teamspeak3 server installed to query current userlist
function telnetGetData ()
{
    ( echo "login ${username} ${passphrase}"; sleep 2; echo "use 1"; sleep 2; echo "clientlist"; sleep 2; echo "quit" ) | telnet  ${server} ${port} > ${tmpDir}/${tmp1}
    ( echo "login ${username} ${passphrase}"; sleep 2; echo "use 1"; sleep 2; echo "servergrouplist"; sleep 2; echo "quit" ) | telnet  ${server} ${port} > ${tmpDir}/${tmp10}
    ( echo "login ${username} ${passphrase}"; sleep 2; echo "use 1"; sleep 2; echo "serverinfo"; sleep 2; echo "quit" ) | telnet  ${server} ${port} > ${tmpDir}/${tmp11}
}

# määääägick :-)
# line by line:
# 1st: all whitespaces to newlines (regex) and write to new file
# 2nd: all lines with "client_nickname" to new file
# 3rd: all lines except those with "serveradmin" to new file
# 4th: all lines with '\s' to whitespace and to new file
# 5th: cut off the prefix "client_nickname=" and keep only the usernames, one name per line
# 6th: copy the clientnames to a new file to work further with
function parseClientList ()
{
    sed -e 's/\s\+/\n/g' ${tmpDir}/${tmp1} > ${tmpDir}/${tmp2}
    grep -e "client_nickname" ${tmpDir}/${tmp2} > ${tmpDir}/${tmp3}
    grep -iv "serveradmin" ${tmpDir}/${tmp3} > ${tmpDir}/${tmp4}
    sed -e 's/\\s/ /g' ${tmpDir}/${tmp4} > ${tmpDir}/${tmp5}
    cat ${tmpDir}/${tmp5} | cut -d "=" -f 2 > ${tmpDir}/${tmp6}
    cp ${tmpDir}/${tmp6} ${tmpDir}/${clientDataDir}/${clientnames}
}

# parses the clientids (clid)
function parseClientIDs ()
{
    grep -e "client_nickname" ${tmpDir}/${tmp7} > ${tmpDir}/${tmp8}
    cat ${tmpDir}/${tmp8} | cut -d " " -f 1 | cut -d "=" -f 2 > ${tmpDir}/${tmp9}
}

# uses the clid's to parse every user's data and write them to file, one file per user
# the data will be used here as well (online time, client platform, ...)
function parseClientData ()
{
    counter=0
    while IFS='' read -r line || [[ -n "$line" ]]; do
        ( echo "login ${username} ${passphrase}"; sleep 2; echo "use 1"; sleep 2; echo "clientinfo clid=$line"; sleep 2; echo "quit" ) | telnet  ${server} ${port} >> ${tmpDir}/${clientDataDir}/client_${counter}
        counter=$((counter+1))
    done < "${tmpDir}/${tmp9}"

    unset counter

    #away status
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            if [[ `sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_away" | cut -d "=" -f 2` == "1" ]] ||
               [[ `sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_output_mute" | cut -d "=" -f 2` == "1" ]] ; then
                echo "1" >> ${tmpDir}/${clientDataDir}/${awaystatus}
            else
                echo "0" >> ${tmpDir}/${clientDataDir}/${awaystatus}
            fi
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

    # online times
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "connection_connected_time" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${onlinetimes}
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

    # client platform
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_platform" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${clplatform}
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

    # client version
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            sed -e 's/\\s/ /g' ${tmpDir}/${clientDataDir}/client_${counter} | sed -e 's/\s\+/\n/g' | grep -iv "client_version_" | grep -e "client_version" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${clversion}
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

    # client country
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_country" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${clcountry}
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

    # client away
    counter=0
    while ( true ) ; do
        if [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; then
            sed -e 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_away" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${clversion}
            counter=$((counter+1))
        else
            break
        fi
    done
    unset counter

}

# Reads all clientnames from $clientnames to collect extra data via query and writes it to file
function readClientsData ()
{
    while IFS='' read -r line || [[ -n "$line" ]]; do
        ( echo "login ${username} ${passphrase}"; sleep 2; echo "use 1"; sleep 2; echo "clientfind pattern=$line"; sleep 2; echo "quit" ) | telnet  ${server} ${port} >> ${tmpDir}/${tmp7}
    done < "${tmpDir}/${clientDataDir}/${clientnames}"
}

# copy the list of usernames to a file accessable by the webserver
function deliverData ()
{
    #client data
    rm -rf ${tmpDir}/${clientDataDir}/client_*
    cp ${tmpDir}/${clientDataDir}/${clientnames} ${serverDir}/names
    cp ${tmpDir}/${clientDataDir}/${onlinetimes} ${serverDir}/onlinetimes
    cp ${tmpDir}/${clientDataDir}/${clplatform} ${serverDir}/platform
    cp ${tmpDir}/${clientDataDir}/${clcountry} ${serverDir}/country
    cp ${tmpDir}/${clientDataDir}/${clversion} ${serverDir}/version
    cp ${tmpDir}/${clientDataDir}/${grpIDs} ${serverDir}/grpIDs
    cp ${tmpDir}/${clientDataDir}/${awaystatus} ${serverDir}/away

    #server data
    cp ${tmpDir}/${serverDataDir}/${srvVersion} ${serverDir}/srvVersion
    cp ${tmpDir}/${serverDataDir}/${srvPlatform} ${serverDir}/srvPlatform
    cp ${tmpDir}/${serverDataDir}/${srvUptime} ${serverDir}/srvUptime
    cp ${tmpDir}/${serverDataDir}/${srvPing} ${serverDir}/srvPing
    cp ${tmpDir}/${serverDataDir}/${srvGrpList} ${serverDir}/srvGrpList
}

# information like uptime, server_platform, server_version, ...
function parseServerInfo ()
{
    sed -e 's/\\s/ /g' ${tmpDir}/${tmp11} | sed -e 's/\s\+/\n/g' | grep -iv "virtualserver_version_" | grep -e "virtualserver_version" | cut -d "=" -f 2 >> ${tmpDir}/${serverDataDir}/${srvVersion}
    sed -e 's/\\s/ /g' ${tmpDir}/${tmp11} | sed -e 's/\s\+/\n/g' | grep -e "virtualserver_platform" | cut -d "=" -f 2 >> ${tmpDir}/${serverDataDir}/${srvPlatform}
    sed -e 's/\\s/ /g' ${tmpDir}/${tmp11} | sed -e 's/\s\+/\n/g' | grep -e "virtualserver_uptime" | cut -d "=" -f 2 >> ${tmpDir}/${serverDataDir}/${srvUptime}
    sed -e 's/\\s/ /g' ${tmpDir}/${tmp11} | sed -e 's/\s\+/\n/g' | grep -e "virtualserver_total_ping" | cut -d "=" -f 2 >> ${tmpDir}/${serverDataDir}/${srvPing}
}

function parseServerGroupList ()
{
    sed 's/\s\+/\n/g' ${tmpDir}/${tmp10} | sed -e 's/\\s/ /g' | sed 's/|sgid/|\nsgid/g' | grep -e "sgid" -e "name=" > ${tmpDir}/${serverDataDir}/${srvGrpList}

    counter=0
    while [[ -f ${tmpDir}/${clientDataDir}/client_${counter} ]] ; do
        sed 's/\s\+/\n/g' ${tmpDir}/${clientDataDir}/client_${counter} | grep -e "client_servergroups" | cut -d "=" -f 2 >> ${tmpDir}/${clientDataDir}/${grpIDs}
        counter=$((counter+1))
    done
}

# obvious, isn't it ?
# the functions are written in this file in order of appearance, that is in the main function, too
function main ()
{
    preceedings
    telnetGetData
    parseClientList
    readClientsData
    parseClientIDs
    parseClientData
    parseServerInfo
    parseServerGroupList
    deliverData
    cleanup
    exit 0
}

# deletes (hopefully) all that mess we did and cleans up space
function cleanup ()
{
    cd ${tmpDir}
    rm -rf ${tmp1}
    rm -rf ${tmp2}
    rm -rf ${tmp3}
    rm -rf ${tmp4}
    rm -rf ${tmp5}
    rm -rf ${tmp6}
    rm -rf ${tmp7}
    rm -rf ${tmp8}
    rm -rf ${tmp9}
    rm -rf ${tmp10}
    rm -rf ${tmp11}
    rm -rf ${clientnames}
    rm -rf ${clientDataDir}

    unset tmpDir
    unset tmp1
    unset tmp2
    unset tmp3
    unset tmp4
    unset tmp5
    unset tmp6
    unset tmp7
    unset tmp8
    unset tmp9
    unset tmp10
    unset tmp11
    unset username
    unset passphrase
    unset server
    unset port
    unset serverDir
    unset clientnames
    unset clientDataDir
    unset serverDataDir
    unset onlinetimes
    unset clplatform
    unset clversion
    unset srvVersion
    unset srvPlatform
    unset srvUptime
    unset srvPing
    unset clcountry
    unset counter
}

main
