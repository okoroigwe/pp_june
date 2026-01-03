#!/bin/bash

# Exit on any error
set -e

# Variables
TOMCAT_VERSION=10.1.10
INSTALL_DIR=/opt/tomcat
ADMIN_USER="admin"
ADMIN_PASS="Admin123"

echo "Updating system packages..."
apt update -y && apt upgrade -y

echo "Installing Java (OpenJDK 11) and wget..."
apt install -y openjdk-11-jdk wget

echo "Creating Tomcat user and group..."
groupadd tomcat || true
useradd -s /bin/false -g tomcat -d $INSTALL_DIR tomcat || true

echo "Downloading Apache Tomcat..."
cd /tmp
wget https://downloads.apache.org/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

echo "Installing Tomcat..."
mkdir -p $INSTALL_DIR
tar xzvf apache-tomcat-$TOMCAT_VERSION.tar.gz -C $INSTALL_DIR --strip-components=1

echo "Setting permissions..."
chown -R tomcat:tomcat $INSTALL_DIR
chmod +x $INSTALL_DIR/bin/*.sh

echo "Creating systemd service for Tomcat..."
cat > /etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Starting Tomcat service..."
systemctl start tomcat
systemctl enable tomcat

echo "Configuring Tomcat admin and manager users..."
cat > $INSTALL_DIR/conf/tomcat-users.xml <<EOL
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="$ADMIN_USER" password="$ADMIN_PASS" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOL

chown tomcat:tomcat $INSTALL_DIR/conf/tomcat-users.xml
chmod 600 $INSTALL_DIR/conf/tomcat-users.xml

echo "Restarting Tomcat to apply user changes..."
systemctl restart tomcat

echo "Tomcat installation completed!"
echo "Access Tomcat Manager at: http://<your-instance-ip>:8080/manager/html"
echo "Login credentials - Username: $ADMIN_USER Password: $ADMIN_PASS"
