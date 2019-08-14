#!/bin/bash

# Script to setup basic CI infra in a single RHEL machine using Docker
# --------------------------------------------------------------------

IP_ADDR=$(/sbin/ifconfig -a | awk '/(cast)/ { print $2 }' | cut -d':' -f2 | head -1)

# Remove any previous installation
yum remove \
        docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine

# Install pre-requisites for docker
yum install -y  \
        yum-utils \
        device-mapper-persistent-data \
        lvm2

# Configure Docker Repo in YUM
yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
yum install --nobest -y \
        docker-ce \
        docker-ce-cli \
        containerd.io

# Enable Docker service
systemctl enable docker

# Start Docker service
systemctl start docker

# Pull required Docker images
docker pull sonatype/nexus3
docker pull jenkins
docker pull postgres
docker pull sonarqube

# Set required permission for the folders
chown -R 999 /etc/sonarqube/
chown -R 999 /var/log/sonarqube/
chown -R 200 /var/lib/nexus3
chown -R 999 /var/lib/sonarqube/data/
chown -R 999 /var/lib/sonarqube/extensions/
chown -R 1000 /var/lib/postgresql/
chown -R 1000 /var/lib/jenkins/

# Start the containers with restart-policy `always`

# Jenkins container:
# - Container name: `jenkins-dtc-devops`
# - Binds with port 8080 (GUI), 50000 (Slave builds) and 50022 (X-SSH)
# - Mounts path `/var/lib/jenkins` of system to `/var/jenkins_home` of container
docker run -d --name jenkins-dtc-devops \
    -p 8080:8080 \
    -p 50000:50000 \
    -p 50022:50022 \
    --restart always \
    -v /var/lib/jenkins:/var/jenkins_home \
    jenkins

# Sonatype Nexus3 OSS container:
# - Container name: `nexus3-dtc-devops`
# - Binds with port 8081 (GUI)
# - Mounts path `/var/lib/nexus3` of system to `/nexus-data` of container
docker run -d --name nexus3-dtc-devops \
    -p 8081:8081 \
    --restart always \
    -v /var/lib/nexus3:/nexus-data \
    sonatype/nexus3

# Postgres container:
# - Container name: `postgres-dtc-devops`
# - Binds with port 5432 (DB)
# - Sets the following ENV Variables inside the container -
#   * POSTGRES_PASSWORD=dtc_devops_admin_P@55w0rd
#	* PGPASSWORD=dtc_devops_admin_P@55w0rd
#	* POSTGRES_USER=dtc_devops_admin
#	* POSTGRES_DB=admin_db
#	* PGDATA=/var/lib/postgresql/data/pgdata
# - Mounts path `/var/lib/postgresql` of system to `/var/lib/postgresql/data/pgdata` of container
docker run -d --name postgres-dtc-devops \
    -p 5432:5432 \
	--restart always \
    -e POSTGRES_PASSWORD=sonar \
	-e PGPASSWORD=sonar \
	-e POSTGRES_USER=sonar \
	-e POSTGRES_DB=sonar \
	-e PGDATA=/var/lib/postgresql/data/pgdata/ \
    -v /var/lib/postgresql:/var/lib/postgresql/data/pgdata \
    postgres

# Sonarqube container:
# - Container name: `sonarqube-dtc-devops`
# - Binds with port 9000 (GUI)
# - Mounts path `/etc/sonarqube` of system to `/opt/sonarqube/conf` of container
# - Mounts path `/var/log/sonarqube` of system to `/opt/sonarqube/logs` of container
# - Mounts path `/var/lib/sonarqube/data` of system to `/opt/sonarqube/data` of container
# - Mounts path `/var/lib/sonarqube/extensions` of system to `/opt/sonarqube/extensions` of container
docker run -d --name sonarqube-dtc-devops \
    -p 9000:9000 \
	--restart always \
    -e sonar.jdbc.username=sonar \
    -e sonar.jdbc.password=sonar \
    -e sonar.jdbc.url=jdbc:postgresql://$(IP_ADDR):5432/sonar \
    -v /etc/sonarqube:/opt/sonarqube/conf \
    -v /var/lib/sonarqube/data:/opt/sonarqube/data \
    -v /var/log/sonarqube:/opt/sonarqube/logs \
    -v /var/lib/sonarqube/extensions:/opt/sonarqube/extensions \
    sonarqube

# Updating system firewall
firewall-cmd --zone=public --permanent --add-port=5432/tcp
firewall-cmd --zone=public --permanent --add-port=8080/tcp
firewall-cmd --zone=public --permanent --add-port=8081/tcp
firewall-cmd --zone=public --permanent --add-port=9000/tcp
firewall-cmd --zone=public --permanent --add-port=50000/tcp
firewall-cmd --zone=public --permanent --add-port=50022/tcp
firewall-cmd --zone=public --permanent --add-masquerade
firewall-cmd --reload
