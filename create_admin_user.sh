#!/bin/bash

if [ -f /.tomcat_admin_created ]; then
	echo "Tomcat 'admin' user already created"
		exit 0
fi
			
#generate password
PASS=${TOMCAT_PASS:-$(cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10| head -n 1)}
_word=$( [ ${TOMCAT_PASS} ] && echo "preset" || echo "random" )

echo "=> Creating and admin user with a ${_word} password in Tomcat"
sed -i -r 's/<\/tomcat-users>//' ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-gui"/>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-script"/>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-jmx"/>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '<role rolename="admin-gui"/>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '<role rolename="admin-script"/>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo "<user username=\"admin\" password=\"${PASS}\" roles=\"manager-gui,manager-script,manager-jmx,admin-gui, admin-script\"/>" >> ${TOMCAT_HOME}/conf/tomcat-users.xml
echo '</tomcat-users>' >> ${TOMCAT_HOME}/conf/tomcat-users.xml 
echo "=> Done!"
touch ${TOMCAT_HOME}/scripts/.tomcat_admin_created

echo "========================================================================"
echo "You can now configure to this Tomcat server using:"
echo ""
echo "    admin:${PASS}"
echo ""
echo "========================================================================"