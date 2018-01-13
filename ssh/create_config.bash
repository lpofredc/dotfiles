#!/bin/bash
# create_config for -- SSH

prgname="SSH"

echo -e "\e[1;36mInstalling ... ${prgname} ... configuration files ...\e[0m"
sleep 1

source INSTALL_ALL/config.bash

main()
{
    # ssh
    if [[ ! ( -d ~/.ssh ) ]] ; then
        mkdir --mode=700 ~/.ssh
    fi
    cp -ifv ${repoPath}/ssh/config ~/.ssh/config

    echo -e "Please unencrypt the ssh config with vim."
    read -p "Do it now? [Y/n]: " decrypt

    if [[ ${decrypt} == "y" || ${decrypt} == "Y" || ${decrypt} == "" ]] ; then
        vim ~/.ssh/config
    elif
        [[ ${decrypt} == "n" || ${decrypt} == "N" ]] ; then
        echo -e "Will not touch ssh config."
        echo -e "Please decrypt it by yourself before using ssh!"
    else
        echo -e "Unrecognized entry."
    fi
}

main
exit 0
