# Basic CI Infrastructure Setup

This project aims at provisioning a basic CI infra setup comprising of the following:
- Jenkins CI Server
- SonarQube Server
- Postgresql as SonarQube's database server
- Sonatype Nexus OSS

## Virtual Machine Requirements

| OS | vCPU (min) | RAM (in GiB) (min) |
| :----: | :----: | :----: |
| RHEL 7+ | 4 | 8 |

## Pre-Requisites

1. This script expects the following directories to be available. If required, these volumes can be separate mounts (like mounting an EBS volume in AWS EC2 Instance).

	Required directories:
	- /etc/sonarqube/
	- /var/log/sonarqube/
	- /var/lib/nexus3
	- /var/lib/sonarqube/data/
	- /var/lib/sonarqube/extensions/
	- /var/lib/postgresql/
	- /var/lib/jenkins/
2. Permissions to login as `root` user.
3. Open the following ports in the cloud portal:
	- 5432 for Postgresql DB Server
	- 8080 for Jenkins CI Server
	- 8081 for Sonatype Nexus 3 Server
	- 9000 for SonarQube Server
	- 50000 for Jenkins Master Slave Configuration (if required)
	- 50022 for Jenkins X-SSH endpoint

## Running the scripts

 1. Login as root user and execute the following commands:
	 ```sh
	 chmod +x ./_init_.sh
	 chmod +x ./_ci_infra_setup_.sh
	 ```
 2. Run `_init_.sh` script. This script will:
	 - `update` and `upgrade` all available packages.
	 - install `firewalld`, enables and start the service using `systemctl`.
	 - disable `selinux`.
	 - change system limit configuration as:
		 - `vm.max_map_count=262144` in `/etc/sysctl.conf`
		 - `fs.file-max=65536` in `/etc/sysctl.conf`
		 - `ulimit -u 4096` in `/etc/security/limits.conf`
		 - `ulimit -n 65536` in `/etc/security/limits.conf`
	  - finally reboot the machine.
3. Once the system restarts, run the `_ci_infra_setup_.sh` script. This script will:
	- install `docker-ce`, enables and start the service using `systemctl`.
	- pulls the following docker images from docker hub:
		- jenkins
		- sonatype/nexus3
		- postgres
		- sonarqube
    - sets required permissions for the folders mentioned in pre-requisites.
    - runs the following docker images and maps the default ports with the same system ports:
	    - jenkins
	    - sonatype/nexus3
	    - postgres
	    - sonarqube
	 - updates the system firewall configuration.

## Credits
- [Kamalakannan R M](mailto:krajagopalma@dxc.com)
