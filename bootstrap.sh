#!/usr/bin/env bash

export LC_ALL=C
NON_INTERCATIVE="false"

for arg in "$@"; do
    if [ "--debug" == "$arg" ]; then
        set -x
        set -e
    fi
    if [ "-y" == "$arg" ]; then
        NON_INTERCATIVE="true"
    fi
done

BASE_URL="https://github.com/softfire-eu"
MANAGERS="experiment-manager security-manager nfv-manager physical-device-manager sdn-manager monitoring-manager"
VENV_NAME="$HOME/.softfire"
SESSION_NAME="softfire"
CODE_LOCATION="/opt/softfire"
CONFIG_LOCATION="/etc/softfire"
CONFIG_FILE_LINKS="https://raw.githubusercontent.com/softfire-eu/experiment-manager/master/etc/experiment-manager.ini \
https://raw.githubusercontent.com/softfire-eu/security-manager/master/etc/template/security-manager.ini \
https://raw.githubusercontent.com/softfire-eu/nfv-manager/master/etc/nfv-manager.ini \
https://raw.githubusercontent.com/softfire-eu/nfv-manager/master/etc/available-nsds.json \
https://raw.githubusercontent.com/softfire-eu/experiment-manager/develop/etc/mapping-managers.json \
https://raw.githubusercontent.com/softfire-eu/monitoring-manager/master/etc/monitoring-manager.ini \
https://github.com/softfire-eu/nfv-manager/raw/master/etc/openstack-credentials.json"
SECURITY_MANAGER_FOLDER="${CONFIG_LOCATION}/security-manager"

function install_deb_requirements {
    sudo apt-get update
    sudo apt-get install -y virtualenv tmux python3-pip build-essential libssl-dev libffi-dev python-dev libmysqlclient-dev wget
}

function install_pip_requirements {
    pip install -r ./requirements.txt > /dev/null 2>&1
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
    echo "actions:    [install|update|clean|start|stop|codestart|codeupdate|codeinstall|purge]"
    echo ""
    echo "install:      install the SoftFIRE Middleware python packages"
    echo "update:       update the SoftFIRE Middleware python packages"
    echo "clean:        clean the SoftFIRE Middleware"
    echo "start:        start the SoftFIRE Middleware via python packages"
    echo "stop:         stop the SoftFIRE Middleware"
    echo "codeinstall:  install the SoftFIRE Middleware source code"
    echo "codeupdate:   update the SoftFIRE Middleware source code"
    echo "codestart:    start the SoftFIRE Middleware via source code"
    echo "purge:        completely remove the SoftFIRE Middleware"
    exit 1

}

function crate_folders {
for dir in ${CONFIG_LOCATION} "/var/log/softfire" "${CONFIG_LOCATION}/users" "${SECURITY_MANAGER_FOLDER}" "${SECURITY_MANAGER_FOLDER}/tmp"; do
    if [ ! -d ${dir} ]; then
        sudo mkdir -p ${dir}
        sudo chown ${USER} ${dir}
    fi
done
}

function download_gui {

    if [ ! -d "${CONFIG_LOCATION}/views" ]; then
        pushd /etc/softfire
        git clone https://github.com/softfire-eu/views.git
    else
        pushd /etc/softfire/views
        git pull
    fi
    popd
}

function copy_config_files {
    pushd ${CONFIG_LOCATION}

    for url in ${CONFIG_FILE_LINKS}; do
        file_name=${url##*/}
        echo "Checking $file_name"
        if [ ! -f ${file_name} ]; then
            wget ${url}
        fi
    done

    popd
}

function remove_venv {
    rm -rf ${VENV_NAME}
}

function remove_databases {
    # Works only for sqlite!
    db_location=$(awk -F ":///" '/^url/ {print $2}' /etc/softfire/experiment-manager.ini)
    rm -rf ${db_location}
    db_location=$(awk -F ":///" '/^url/ {print $2}' /etc/softfire/nfv-manager.ini)
    rm -rf ${db_location}

    echo -n Mysql root Password:
    read -s mysql_password
    echo
    mysql -u root -p${mysql_password} -e "drop database if exists softfire;"
}

function finish_install_message {
    echo "Installation was executed. Please configure the system by changing these files:"
    echo ""
    for url in ${CONFIG_FILE_LINKS}; do
        file_name=${url##*/}
        echo "* /etc/softfire/$file_name"
    done
}

function generate_users {
    if [ "true" == "$NON_INTERCATIVE" ]; then
        python generate_cork_files.py "${CONFIG_LOCATION}/users/" -y
    else
        python generate_cork_files.py "${CONFIG_LOCATION}/users/"
    fi
}

function main {

    if [ "0" == "$#" ]; then
        usage
    fi
    if [ "1" == "$#" -a "--debug" == "$1" ]; then
        usage
    fi

    if [ "--debug" == "$1" ]; then
        shift
    fi
    action=$1
    shift
    args=$@
    case ${action} in
    "install")

        install_deb_requirements
        crate_folders
        enable_virtualenv

        for m in ${MANAGERS}; do
            install_manager ${m}
        done

        generate_users

        copy_config_files

        download_gui

        finish_install_message
       ;;

     "start")
        tmux new -d -s ${SESSION_NAME}

        for m in ${MANAGERS}; do
            echo "Starting ${m}"
            tmux neww -t ${SESSION_NAME} -n "${m}" "source $VENV_NAME/bin/activate && ${m}"
        done


     ;;
     "clean")
        echo -n Mysql root Password:
        read -s mysql_password
        echo

        mysql -u root -p${mysql_password} -e "drop database if exists softfire; create database softfire;"

        generate_users
     ;;
     "update")
        enable_virtualenv

        for m in ${MANAGERS}; do
            install_manager ${m} "--upgrade"
        done

        download_gui
     ;;
     "codeupdate")
         pushd ${CODE_LOCATION}

         for x in `ls`; do
            pushd $x && git checkout . && git pull && popd;
         done
         popd
         download_gui
     ;;
     "codeinstall")

        install_deb_requirements
        crate_folders
        enable_virtualenv
        install_pip_requirements

        if [ ! -d ${CODE_LOCATION} ]; then
            sudo mkdir ${CODE_LOCATION}
            sudo chown -R ${USER} ${CODE_LOCATION}
        else
            echo "Folder '/opt/softfire' exists already, delete it before code install"
            exit 1
        fi

        pushd /opt/softfire

        for m in ${MANAGERS}; do
            git clone "${BASE_URL}/${m}.git"
            pushd ${m}
            exist_develop=$(git ls-remote --heads "${BASE_URL}/${m}.git" develop | wc -l)
            if [ ${x} == "1" ]; then
                git chechout develop
            fi
        done

        popd

        copy_config_files
        generate_users
        finish_install_message
     ;;
     "codestart")

        enable_virtualenv
        install_pip_requirements
        if [ -n ${args} ]; then
            MANAGERS=${args}
        fi

        for m in ${MANAGERS}; do
            pip uninstall ${m} -y > /dev/null 2>&1
        done
        deactivate

        tmux new -d -s ${SESSION_NAME}

        for m in ${MANAGERS}; do
            echo "Starting ${m}"
            tmux neww -t ${SESSION_NAME} -n "${m}" "source $VENV_NAME/bin/activate && cd ${CODE_LOCATION}/${m} && ./${m}; bash"
        done
     ;;

     "stop")
        tmux kill-session -t ${SESSION_NAME}
     ;;

     "clean")
        remove_venv
     ;;

     "purge")
        read -p "Are you sure you want to purge all (y/n)?" choice
        case "$choice" in
          y|Y )
            remove_venv
            rm -rf ${CODE_LOCATION}
            # remove_databases
            echo "To complete the purging, delete the folder ${CONFIG_LOCATION}"
            ;;
          n|N )
            echo "ah ok..."
            ;;
          * )
            echo "invalid choice"
            ;;
        esac

     ;;
    esac

}


main $@
