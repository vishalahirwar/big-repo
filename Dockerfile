FROM centos
MAINTAINER Pravesh Sharma

ARG OPENJDK_VERSION=1.8.0
ARG TOMCAT_MAJOR=8
ARG TOMCAT_VERSION=8.5.50

# Ensure root user is used               
#USER root 
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
RUN mkdir -p /data/wipo-proof/logs/
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

ENV WDTS_BUSINESS_URL=http://biz:8082/wdts-business/services 
ENV OIDC_DISCOVERY_URL=https://www5.wipo.int/am/oauth2/.well-known/openid-configuration
ENV OIDC_CLIENT_ID=fake_id
ENV OIDC_CLIENT_SECRET=fake_to_be_replaced
ENV OIDC_CLIENT_RETURN_URL=http://alb/wdts1/home.xhtml
ENV OIDC_CLIENT_LOGOUT_URL=http://alb/wdts1/logout.xhtml

ADD setenv.sh $TOMCAT_HOME/bin

# Create tomcat user hee
RUN groupadd -r tomcat && useradd -g tomcat -d ${TOMCAT_HOME} -s /sbin/nologin  -c "Tomcat user" tomcat && chown -R tomcat:tomcat ${TOMCAT_HOME}
RUN chown -R tomcat:tomcat /data

EXPOSE 8080
EXPOSE 8009

USER tomcat
# Launch Tomcat
CMD ["./bin/catalina.sh", "run"]

# COPY path-to-your-application-war path-to-webapps-in-docker-tomcat
COPY wdts.war ${TOMCAT_HOME}/webapps/
COPY truststore.jks ${TOMCAT_HOME}/

### Command to run the container 
## docker container run -it -v C:/data/wipo-proof/logs/:/data/wipo-proof/logs -e JAVA_OPTS="-DWIP_CONFIG_DIR=/usr/local/tomcat -DWIP_TIMEOUT=100 -Djavax.net.ssl.trustStore=/usr/local/tomcat/truststore.jks -Djavax.net.ssl.trustStorePassword=changeit -Dwdts-business-url=http://10.145.133.23:8083/wdts-business/services -Doidc.discovery.url=https://www3dev.wipo.int/am/oauth2/.well-known/openid-configuration -Doidc.client.id=oidcWdtsDev -Doidc.client.secret=C3xh1ts8Okvds0zqFFjA -Doidc.client.return_url=https://pctdev.wipo.int/wdts1/home.xhtml -Doidc.client.logout_url=https://pctdev.wipo.int/wdts1/logout.xhtml -Doidc.client.scope=openid,profile,email,loa" --publish 8080:8080 wdts-web 