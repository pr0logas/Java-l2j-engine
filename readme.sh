##: Centos 8 install // Java 11
##: Author: pr0logas // roothere@protonmail.com

# Centos 8 update
dnf update -y
sync ; reboot

# Required packages
dnf install epel-release -y
dnf install git vim htop ncdu unzip wget ufw -y

# Preparation of Java
mkdir -p /opt/l2j && cd /opt/l2j
wget https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
tar -xf openjdk-11.0.2_linux-x64_bin.tar.gz
ln -s /opt/jdk-11.0.2/bin/java /usr/bin/java
ln -s /opt/jdk-11.0.2/bin/javac /usr/bin/javac
java --version

# Maven
wget https://www-us.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -P /tmp
tar xf /tmp/apache-maven-*.tar.gz -C /opt
ln -s /opt/apache-maven-3.6.3 /opt/maven
vi /etc/profile.d/maven.sh
# Paste
export JAVA_HOME=/opt/jdk-11.0.2/
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# MariaDB-server
dnf install mariadb-server -y
mariadb -u root
MariaDB > CREATE USER 'l2j'@'%' IDENTIFIED BY 'l2jserver2019';
MariaDB > GRANT ALL PRIVILEGES ON *.* TO 'l2j'@'%' IDENTIFIED BY 'l2jserver2019';
MariaDB > FLUSH PRIVILEGES;

# Get the Source Code
mkdir -p /opt/l2j/git && cd /opt/l2j/git
git clone https://bitbucket.org/l2jserver/l2j-server-login.git
git clone https://bitbucket.org/l2jserver/l2j-server-game.git
git clone https://bitbucket.org/l2jserver/l2j-server-datapack.git

# Build
cd /opt/l2j/git/l2j-server-login && mvn install
cd /opt/l2j/git/l2j-server-game && mvn install
cd /opt/l2j/git/l2j-server-datapack && mvn install

# Deploy the Server
mkdir -p /opt/l2j/server/login && mkdir -p /opt/l2j/server/game
unzip /opt/l2j/git/l2j-server-login/target/l2jlogin-*.zip -d /opt/l2j/server/login
unzip /opt/l2j/git/l2j-server-game/target/l2j-server-game-*.zip -d /opt/l2j/server/game
unzip /opt/l2j/git/l2j-server-datapack/target/l2j-server-datapack-*.zip -d /opt/l2j/server/game

# Get L2J CLI and Install the Database
mkdir -p /opt/l2j/cli && cd /opt/l2j/cli
wget https://l2jserver.com/files/binary/cli/l2jcli-1.0.2.zip -P /tmp
unzip /tmp/l2jcli-*.zip -d /opt/l2j/cli
chmod 755 l2jcli.sh
./l2jcli.sh
db install -sql /opt/l2j/server/login/sql -u l2j -p l2jserver2019 -m FULL -t LOGIN -c -mods
db install -sql /opt/l2j/server/game/sql -u l2j -p l2jserver2019 -m FULL -t GAME -c -mods
quit

# Configuration for game service (no more bash loops)
vim /etc/systemd/system/l2game.service

# Paste
[Unit]
Description=L2 game engine daemon & service
After=network.target

[Service]
User=root
Type=simple
WorkingDirectory=/opt/l2j/server/game
ExecStart=/usr/bin/java -Xms1g -Xmx2g -jar l2jserver.jar
Restart=always
RestartSec=120
TimeoutSec=900

[Install]
WantedBy=default.target

# Configuration for login service (no more bash loops)
vim /etc/systemd/system/l2login.service

# Paste
[Unit]
Description=L2 login engine daemon & service
After=network.target

[Service]
User=root
Type=simple
WorkingDirectory=/opt/l2j/server/login
ExecStart=/usr/bin/java -Xms256m -Xmx512m -jar l2jlogin.jar
Restart=always
RestartSec=120
TimeoutSec=900

[Install]
WantedBy=default.target

# Create Administrator Account
cd /opt/l2j/cli
./l2jcli.sh
account create -u Zoey76 -p -a 8
quit

# Firewall update
ufw allow 2106/tcp 
ufw allow 7777/tcp

# Enable & start the services
systemctl enable l2game.service l2login.service
systemctl start l2game.service l2login.service
systemctl status l2game.service l2login.service

# Debuging
journalctl -f -u l2game.service
journalctl -f -u l2login.service
systemctl restart l2login.service l2game.service
