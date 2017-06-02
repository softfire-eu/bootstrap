#!/usr/bin/env bash

for arg in "$@"; do
    if [ "--debug" == "$arg" ]; then
        set -x
        set -e
    fi
done

MANAGERS="experiment-manager nfv-manager physical-device-manager sdn-manager"
VENV_NAME="~/.softfire"
SESSION_NAME="softfire"
CODE_LOCATION="/opt/softfire"
CONFIG_FILE_LINKS="https://raw.githubusercontent.com/softfire-eu/experiment-manager/master/etc/experiment-manager.ini \
https://raw.githubusercontent.com/softfire-eu/nfv-manager/master/etc/nfv-manager.ini \
https://raw.githubusercontent.com/softfire-eu/nfv-manager/master/etc/available-nsds.json"

function install_requirements {
    sudo apt-get update
    sudo apt-get install -y virtualenv tmux mysql-server python3-pip
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
    echo "actions:    [install|update|clean|start|codestart|codeupdate]"
    exit 1

}

function crate_folders {
for dir in "/etc/softfire" "/var/log/softfire" "/etc/softfire/users"; do
    if [ ! -d $dir ]; then
        sudo mkdir -p $dir
        sudo chown $USER $dir
    fi
done
}

function download_gui {

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
    if [ "1" == "$#" -a "--debug" == "$1" ]; then
        usage
    fi

    for var in "$@";
    do
        case ${var} in
        "install")

            install_requirements
            crate_folders
            enable_virtualenv
            
            python generate_cork_files.py /etc/softfire/users/
            
            for m in ${MANAGERS}; do
                install_manager ${m}
            done

            copy_config_files

            download_gui
           ;;

         "start")
            tmux new -d -s ${SESSION_NAME}

            for m in ${MANAGERS}; do
                echo "Starting ${m}"
                tmux neww -t ${SESSION_NAME} -n "${m}" "source $VENV_NAME/bin/activate && ${m}"
                sleep 2
            done


         ;;
         "clean")
            echo -n Mysql root Password:
            read -s mysql_password
            echo

            mysql -u root -p${mysql_password} -e "drop database if exists softfire; create database softfire;"

            python generate_cork_files.py
         ;;
         "update")
            enable_virtualenv

            for m in ${MANAGERS}; do
                install_manager ${m} "--upgrade"
            done

            download_gui
         ;;
         "codeupdate")
             pushd /opt/softfire

             for x in `ls`; do
                pushd $x && git checkout . && git pull && popd;
             done
             popd
             download_gui
         ;;
         "codestart")
            tmux new -d -s ${SESSION_NAME}

            for m in ${MANAGERS}; do
                echo "Starting ${m}"
                tmux neww -t ${SESSION_NAME} -n "${m}" "source $VENV_NAME/bin/activate && cd ${CODE_LOCATION}/${m} && ./${m}"
                sleep 2
            done
         ;;
         "stop")
            tmux kill-session -t ${SESSION_NAME}
         ;;
        esac

    done

}


main $@
