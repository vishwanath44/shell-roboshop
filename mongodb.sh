#!/bin/bash

USERID=$(id -u)
SCRIPT_NAME=$(basename "$0")
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Create log directory first
mkdir -p $LOGS_FOLDER

# Root check
if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

echo -e "$Y Configuring MongoDB Repository $N" | tee -a $LOGS_FILE

cat <<EOF >/etc/yum.repos.d/mongo.repo
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

VALIDATE $? "Creating MongoDB repo"

dnf clean all &>>$LOGS_FILE
dnf makecache &>>$LOGS_FILE

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Server"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB Service"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB Service"

sed -i 's/^  bindIp:.*$/  bindIp: 0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB Service"

echo -e "$G MongoDB Installation Completed Successfully $N" | tee -a $LOGS_FILE