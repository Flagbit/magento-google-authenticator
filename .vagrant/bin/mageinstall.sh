#! /bin/sh
# /usr/local/bin/mageinstall
#

### Start up #################################
	expectedargs=1
	ebadargs=65

	if [ $# -lt ${expectedargs} ]
	then
  		echo "Usage: `basename $0` magentoversion --with-sample-data"
  		echo "Available Magento-Versions"
  		ls -l /usr/local/src/magento/versions/ | grep ^d | nawk '{print $NF}'
  		exit ${ebadargs}
	fi
	
	sampleData=false
	
	for i in "$@"
	do
		case "$i" in
	     "--with-sample-data")
	            sampleData=true
	            ;;
		esac
	done

### Settings #################################

	mysql=`which mysql`
	entity=${1}
	dbroot="vagrant"
	dbhost="localhost"
	dbname=${1}
	dbuser=${1}
	dbpass="vagrant1"
	url="http://localhost:8080/${entity}"
	version=${1}
	sample="y"

### Installer #################################

	versionspath="/usr/local/src/magento/versions"
	temppath="/usr/local/src/magento/tmp/${version}"
	projectfiles="/usr/local/src/magento/deployment"

### Installer: Mapping mountpoints ################

	echo [+] mapping mountpoints to /var/www/${version}
	
	checkFile="/var/www/${version}"
       sudo cat /proc/mounts |grep ${checkFile} > /dev/null

	if [ $? -eq 0 ] ; then
		echo [-] ${checkFile} is already mounted
		echo [+] unmounting ${checkFile}
		sudo umount -f ${checkFile}
	fi

	if [ -d ${checkFile} ]; then
		echo [-] ${checkFile} exists
		echo [+] deleting ${checkFile}
		rm -r ${checkFile}
	fi

	mkdir ${checkFile}

	checkFile="${temppath}"
	if [ -d ${checkFile} ]; then
		echo [-] ${checkFile} exists
		echo [+] deleting ${checkFile}
		rm -r ${checkFile}
	fi
	
	mkdir ${checkFile}  

	sudo mount -t aufs -o br:/usr/local/src/magento/tmp/${version}/ none /var/www/${version}/
	echo [+] mount /usr/local/src/magento/tmp/${version}/ /var/www/${version}/

	sudo mount -o remount,append:/usr/local/src/magento/deployment /var/www/${version}/
	echo [+] mount /usr/local/src/magento/deployment/ /var/www/${version}/

	sudo mount -o remount,append:/usr/local/src/magento/versions/${version} /var/www/${version}/
	echo [+] mount /usr/local/src/magento/versions/${version}/ /var/www/${version}/ 
	

### Installer: Database ########################
       
    echo [+] importing Database

	sql="DROP DATABASE IF EXISTS \`${dbname}\`;"
	$mysql -uroot -p${dbroot} -e "${sql}"

       sql="CREATE DATABASE \`${dbname}\`;"
	$mysql -uroot -p${dbroot} -e "${sql}"

       sql="GRANT ALL ON *.* TO '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';"
	$mysql -uroot -p${dbroot} -e "${sql}"

       sql="FLUSH PRIVILEGES;"
	$mysql -uroot -p${dbroot} -e "${sql}"
	  
### Installer: Sample-Data ########################	   
  
    if [ ${sampleData} = "true" ]
    then
		echo [+] extracting Sample-Data
	
		sudo tar -zxf ${versionspath}/magento-sample-data-1.2.0.tar.gz -C /var/www/${version}/
	       sudo mv /var/www/${version}/magento-sample-data-1.2.0/media/* /var/www/${version}/media/
	       sudo mv /var/www/${version}/magento-sample-data-1.2.0/magento_sample_data_for_1.2.0.sql /var/www/${version}/data.sql
	
	    $mysql -h ${dbhost} -u "${dbuser}" -p${dbpass} ${dbname} < /var/www/${version}/data.sql
    fi

### Installer: Userrights ########################  
      
	echo [+] preparing Userights

		path="/usr/local/src/magento/versions/${version}"
		sudo chmod o+w ${path}/var ${path}/var/.htaccess ${path}/app/etc
	
	echo [+] prepare ${path}/install.php
		
		sudo chmod -R 775 ${path}/media ${path}/var
		sudo chown vagrant:www-data ${path}/* -R    
              
	echo [+] cleaning up Magento

       sudo rm -rf downloader/pearlib/cache/* downloader/pearlib/download/*
       sudo rm -rf magento-sample-data-1.2.0/
       sudo rm -rf index.php.sample .htaccess.sample php.ini.sample LICENSE.txt STATUS.txt data.sql

### Installer: Magentoinstallation ########################
	cd /var/www/${version}
	
 	echo [+] Installing Magento

       php -f install.php -- \
       --license_agreement_accepted "yes" \
       --locale "de_DE" \
       --timezone "Europe/Berlin" \
       --default_currency "USD" \
       --db_host "${dbhost}" \
       --db_name "${dbname}" \
       --db_user "${dbuser}" \
       --db_pass "${dbpass}" \
       --url "${url}" \
       --use_rewrites "yes" \
       --use_secure "no" \
       --secure_base_url "" \
       --use_secure_admin "no" \
       --admin_firstname "flagbit" \
       --admin_lastname "flagbit" \
       --admin_email "info@flagbit.de" \
       --admin_username "admin" \
       --admin_password "${dbpass}"

	echo "Magento under ${url} installed"

       exit
       
