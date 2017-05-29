#!/usr/bin/env bash

MANAGERS="experiment-manager nfv-manager"
VENV_NAME=".softfire"
CONFIG_FILE_LINKS="https://raw.githubusercontent.com/softfire-eu/experiment-manager/master/etc/experiment-manager.ini https://raw.githubusercontent.com/softfire-eu/nfv-manager/master/etc/nfv-manager.ini"

function install_requirements {
    sudo apt-get install virtualenv tmux
}
function install_manager() {
    manager_name=$1
    if [ "$2" == "--upgrade" ]; then
        pip install --upgrade ${manager_name}
    else
        pip install ${manager_name}
    fi
}

function enable_virtualenv {
  echo "Creating virtualenv"
  if [ ! -d ${VENV_NAME} ]; then
    virtualenv --python=python3 ${VENV_NAME}
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


    if [ ! -d "/etc/softfire/views" ]; then
        pushd /etc/softfire
        git clone https://github.com/softfire-eu/views.git
    else
        pushd /etc/softfire/views
        git pull
    fi
    popd
}

function copy_config_files {
    # TODO use different method
    if [ ! -d "/etc/softfire" ]; then
        mkdir -p "/etc/softfire"
    fi
    pushd /etc/softfire

    for url in ${CONFIG_FILE_LINKS}; do
        file_name=${url##*/}
        echo "Checking $file_name"
        if [ ! -f ${file_name} ]; then
            wget ${url}
        fi
    done

    popd
}

function main {

    if [ "0" == "$#" ]; then
        usage
    fi

    for var in "$@";
    do
        case ${var} in
        "install")

            install_requirements
            enable_virtualenv

            for m in ${MANAGERS}; do
                install_manager ${m}
            done

            copy_config_files

            downalod_gui
           ;;

         "start")
            tmux new -d -s "softfire"

            for m in ${MANAGERS}; do
                tmux neww -t softfire -n "${m}" "source $VENV_NAME/bin/activate && ${m}"
            done


         ;;
         "clean")
         ;;
         "update")
            enable_virtualenv

            for m in ${MANAGERS}; do
                install_manager ${m} "--upgrade"
            done

            downalod_gui
         ;;
        esac

    done

}


main $@