#!/usr/bin/env bash

MANAGERS="experiment-manager nfv-manager"
VENV_NAME=".softfire"

function install_requirements {
    sudo apt-get install virtualenv tmux
}
function install_manager() {
    manager_name=$1
    if [ ]
    pip install ${manager_name}
}

function enable_virtualenv {
  echo "Creating virtualenv"
  if [ ! -d ${VENV_NAME} ]; then
    virtualenv --python=python3 venv
   fi
   echo "created virtual env"
  . "$VENV_NAME/bin/activate"
}

function usage {
    echo "$0 <action>"
    echo ""
    echo "actions:    [install|update|clean|start]"
    exit 1

}

function downalod_gui {
    if [ ! -d "/etc/softfire" ]; then
        mkdir -p "/etc/softfire"
    fi

    pushd /etc/softfire

    git clone https://github.com/softfire-eu/views.git
}

function main {

    if [ "1" == "$#" ]; then
        usage
    fi

    for var in "$@";
    do
        case ${var} in
        "install")

            install_requirements

            for m in ${MANAGERS}; do
                install_manager ${m}
            done

            downalod_gui
           ;;

         "start")
            tmux new -d -s "softfire"

            for m in ${MANAGERS}; do
                tmux -t "softfire" new-window -n "${m}" ${m}
            done


         ;;
         "clean")
         ;;
         "update")
            for m in ${MANAGERS}; do
                install_manager ${m} "--update"
            done
         ;;
        esac

    done

}