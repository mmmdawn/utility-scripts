#!/bin/bash

DEFAULT_SHELL=$(which bash)
DEFAULT_GROUPS=("docker")
 

usage() {
  echo ""
  echo "Usage: $0 [ -n USERNAME ] [Options...]"
  echo "Options:"
  echo "  -g GROUP          Primary group of new user. This group must already exist"
  echo "  -s SHELL_NAME     Default shell of new user. This can be \"bash\" or \"fish\" or any shell already installed on the computer. Default is \"bash\"."
  echo "  -k \"SSH_KEY\"      Public key to add. This must be enclosed in double quotes."
  echo "  -h                Print this help message."
  echo ""
  echo "This command must be executed with sudo privileges."
  echo ""
}
exit_abnormal() {
  echo ""
  echo "Run \"$0 -h\" for usage."
  echo ""
  exit 1
}

while getopts ":n:g:s:k:h" options; do

  case "${options}" in
    n)
      NAME=${OPTARG};
      if ! [[ -z "$(getent passwd $NAME)" ]]; then
        echo ""
        echo "Error: Username already exist"
        exit_abnormal
      fi
      ;;

    g)
      GROUP=${OPTARG};

      for group in ${DEFAULT_GROUPS[@]}; do
        if [[ "$group" == $GROUP ]]; then
          GROUP="";
          break;
        fi
      done

      if [[ -z "$(getent group $GROUP)" ]]; then
        echo ""
        echo "Error: Group does not exist"
        exit_abnormal
      fi
      ;;

    s)
      INP_SH=${OPTARG};

      FIND_SH=$(grep $INP_SH /etc/shells)
      if [[ -z "$FIND_SH" ]]; then
        echo ""
        echo "Error: $INP shell not found"
        exit_abnormal
      fi

      SH=$(which $INP_SH 2>/dev/null);
      ;;

    k)
      KEY=${OPTARG};
      ;;

    h)
      usage
      exit 0
      ;;

    :)
      echo ""
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;

    *)
      usage;
      exit 1
      ;;

  esac
done


#**************************************************************
if [[ "$EUID" != 0 ]]; then
  echo ""
  echo "Please run with sudo privileges";
  exit_abnormal
fi

if [[ -z "$NAME" ]]; then
  echo ""
  echo "Error: Username is required"
  exit_abnormal
fi

if [[ -z "$SH" ]]; then
  SH=$DEFAULT_SHELL
fi


# All setups done. Start creating...
#**************************************************************
useradd -m -s $SH $NAME;


#**************************************************************
for group in ${DEFAULT_GROUPS[@]}; do
  usermod -aG $group $NAME;
done

if ! [[ -z "$GROUP" ]]; then
  usermod -aG $GROUP $NAME;
fi


#**************************************************************
if ! [[ -z "$KEY" ]]; then
  runuser -l $NAME -c "mkdir .ssh";
  runuser -l $NAME -c "echo $KEY >> .ssh/authorized_keys";
fi

#**************************************************************
passwd -d $NAME;
