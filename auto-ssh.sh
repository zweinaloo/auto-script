#! /bin/sh

# 假设1: 所有remote机器上都存在一名与本机当前登录用户同名的用户
# 假设2：这些用户都有路径相同的Home目录
# 假设3：这些用户都有相同的登录密码  
# 假设4：remote机器安装了ssh-server和expect

MAIN_DIR="$HOME/auto-script"
EXP_DIR="$MAIN_DIR/exp-passwd"
PUB_DIR="$MAIN_DIR/pub"
USER=`whoami`
PASSWORD=
TYPE=

usage() {
    echo "usage: $0 [-p password] [-t p2p|m2s] [-x]"
}

while getopts t:p:x OPT
do
    case $OPT in
    p)  PASSWORD=$OPTARG
        ;;
    t)  TYPE=$OPTARG
        ;;
    x)  set -x
        ;;
    ?)  echo "Unrecognized option: $OPT"
        usage
        exit 1
    esac
done

shift $(($OPTIND - 1))
    
if [ ! "$PASSWORD" ]
then
    echo "Unspecifed Password!"
    usage
    exit 1
fi

if [ "$TYPE" != "p2p" ] && [ "$TYPE" != "m2s" ]
then 
    echo "Unknown type: $TYPE"
    usage
    exit 1
fi

if [ "$TYPE" = "m2s" ]
then
    # 本机用户生成公钥
    expect $EXP_DIR/ssh-keygen.exp $HOME
    cp $HOME/.ssh/id_rsa.pub $PUB_DIR/`hostname`.pub
fi

# 将auto-srcipt拷贝到remote
cat $MAIN_DIR/hosts |
    while read HOST
    do  
        expect $EXP_DIR/scp.exp $USER $HOST $PASSWORD $MAIN_DIR $HOME
        
        if [ "$TYPE" = "m2s" ]
        then 
            # 将公钥加入remote的 ~/.ssh/authorized_keys
            expect $EXP_DIR/ssh-cmd.exp $USER $HOST $PASSWORD "mkdir -p $HOME/.ssh ; cat $PUB_DIR/`hostname`.pub >> $HOME/.ssh/authorized_keys"
        fi
    done

if [ "$TYPE" = "p2p" ]
then
    # 公钥分发    
    cat $MAIN_DIR/hosts |
        while read HOST
        do 
            expect $EXP_DIR/ssh-cmd.exp $USER $HOST $PASSWORD "/bin/sh $MAIN_DIR/pub-scatter.sh $MAIN_DIR $EXP_DIR $PUB_DIR $PASSWORD"
        done
fi        
