FROM centos
MAINTAINER vishal

ARG OPENJDK_VERSION=1.8.0
ARG TOMCAT_MAJOR=8
ARG TOMCAT_VERSION=8.5.47

# Ensure root user is used here               
USER root 
# Install required libs
RUN yum update -y
RUN yum install -y sudo

# Install OpenJDK
RUN yum install -y "java-${OPENJDK_VERSION}-openjdk-devel"

ARG TOMCAT_HOME=/usr/local/tomcat

ARG TOMCAT_NAME=apache-tomcat-${TOMCAT_VERSION}
ARG TOMCAT_FILE=${TOMCAT_NAME}.tar.gz

## ARG TOMCAT_URL=http://mirror.easyname.ch/apache/tomcat/tomcat-8/v8.5.46/bin/apache-tomcat-8.5.46.tar.gz

ARG TOMCAT_URL=http://mirror.easyname.ch/apache/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

RUN mkdir -p ${TOMCAT_HOME}
RUN mkdir -p /data/iap/logs/
WORKDIR ${TOMCAT_HOME}

ARG CURL_CMD="curl -k"
RUN ${CURL_CMD} -O ${TOMCAT_URL}

RUN tar -xf ${TOMCAT_FILE} --strip-components 1 --directory ${TOMCAT_HOME}
RUN rm -f ${TOMCAT_FILE}

###delete webapps
RUN rm -rf ${TOMCAT_HOME}/webapps/docs
RUN rm -rf ${TOMCAT_HOME}/webapps/examples
RUN rm -rf ${TOMCAT_HOME}/webapps/manager
RUN rm -rf ${TOMCAT_HOME}/webapps/host-manager
RUN rm -rf ${TOMCAT_HOME}/webapps/ROOT/*.*

ENV IAP_BUSINESS_URL=http://biz:8082/iap-business/services 
ENV OIDC_DISCOVERY_URL=https://www5.wipo.int/am/oauth2/.well-known/openid-configuration
ENV OIDC_CLIENT_ID=fake_id
ENV OIDC_CLIENT_SECRET=fake_to_be_replaced
ENV OIDC_CLIENT_RETURN_URL=http://alb/iap/home.xhtml
ENV OIDC_CLIENT_LOGOUT_URL=http://alb/iap/logout.xhtml

# Create Tomcat admin user
ADD create_admin_user.sh $TOMCAT_HOME/scripts/create_admin_user.sh
ADD setenv.sh $TOMCAT_HOME/bin
ADD index.html ${TOMCAT_HOME}/webapps/ROOT/
RUN chmod +x $TOMCAT_HOME/scripts/*.sh

# Create tomcat user
RUN groupadd -r tomcat && useradd -g tomcat -d ${TOMCAT_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat && chown -R tomcat:tomcat ${TOMCAT_HOME}
RUN chown -R tomcat:tomcat /data

EXPOSE 8080
EXPOSE 8009

USER tomcat
WORKDIR $TOMCAT_HOME

# COPY path-to-your-application-war path-to-webapps-in-docker-tomcat
#COPY truststore.jks ${TOMCAT_HOME}/
COPY wip.properties ${TOMCAT_HOME}/
COPY iap.war ${TOMCAT_HOME}/webapps/
COPY common-res.war ${TOMCAT_HOME}/webapps/

# Launch Tomcat
CMD ["./bin/catalina.sh", "run"]

