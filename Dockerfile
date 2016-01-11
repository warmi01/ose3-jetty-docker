#
# This image provides a base STI builder image for building and running jetty applications.
# Recommendation: Create a company wide base image from an OS and install basic tools. 
# Maintain a git project like this and have it build using a CI tool and push it to appropriate docker registory.
# Use that image as the base for rest of the STI builder images, such as, tomcat, Nodejs etc.
# IMPORTANT: Follow Docker image creation best practices https://docs.docker.com/articles/dockerfile_best-practices/
# Each line in this file will become a docker layer and it will have a huge impact on efficiency.
FROM jetty

ENV JETTY_LOGS $JETTY_HOME/logs
#RUN mkdir -p "$JETTY_LOGS"
RUN chown -R jetty:jetty "$JETTY_LOGS"
RUN chmod og+w /tmp/jetty
RUN chmod og+w "$JETTY_LOGS"
RUN chmod og+w /run/jetty


RUN mkdir /usr/local/sti 

# Default destination of scripts and sources, this is where assemble will look for them
LABEL io.openshift.s2i.scripts-url=image:///usr/local/sti
LABEL version="1.0"
LABEL description="Base Jetty Openshift3 builder images that takes WAR or Folders and deploys them.  \
This is to mimic what App Former does by taking WAR files are deploying them to gears. \
use this as the example builder image to build other builder images "

# BASE STI files for this image creation
# Copy the builder STI scripts from <git>/sti folder to image /usr/local/sti
ADD ./sti/ /usr/local/sti

# May be a bug in os3 - STI needs these scripts to be executable
RUN chmod +x /usr/local/sti/* 

ADD ./conf/* /var/lib/jetty/resources/
ADD ./lib/* /usr/local/jetty/lib/ext/

EXPOSE 8080

#CMD ["/usr/local/sti/usage"]
#CMD ["jetty.sh","-d","run"]
CMD ["java","-Djava.io.tmpdir=/tmp/jetty","-Djetty.logging.dir=/var/lib/jetty/logs","-jar","/usr/local/jetty/start.jar"]
