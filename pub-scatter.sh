#! /bin/bash
# 当前 [`pwd` eq "$HOME"] 为真
# 由auto-ssh.sh调用，不要单独运行

MAIN_DIR=$1
EXP_DIR=$2
PUB_DIR=$3
PASSWORD=$4

# 本机用户生成公钥
expect $EXP_DIR/ssh-keygen.exp $HOME
cp $HOME/.ssh/id_rsa.pub $PUB_DIR/`hostname`.pub

cat $MAIN_DIR/hosts |
    while read HOST
    do
        expect $EXP_DIR/scp.exp $USER $HOST $PASSWORD $PUB_DIR/`hostname`.pub $PUB_DIR
        
        # 将公钥加入remote的 ~/.ssh/authorized_keys
        expect $EXP_DIR/ssh-cmd.exp $USER $HOST $PASSWORD "mkdir -p $HOME/.ssh ; cat $PUB_DIR/`hostname`.pub >> $HOME/.ssh/authorized_keys"
    done
