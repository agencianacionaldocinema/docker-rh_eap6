FROM jboss/base-jdk:8

ENV JBOSS_HOME /opt/jboss/jboss
ENV EAP_INSTALLER=jboss-eap-6.4.0-installer.jar
ENV EAP_PATCH_1=jboss-eap-6.4.9-patch.zip
ENV EAP_PATCH_2=jboss-eap-6.4.16-patch.zip
ENV SSO_ADAPTER=rh-sso-7.1.0-eap6-adapter.zip
ENV EAP_INSTALLER_URL=https://www.dropbox.com/sh/6nd9w26h8i9q7kj/AAAbcyQpocjZG5aS1DOmNmYxa/jboss-eap-6.4.0-installer.jar?dl=1
ENV EAP_PATCH_1_URL=https://www.dropbox.com/sh/6nd9w26h8i9q7kj/AAB-ctr59Y52pBiVU7gaJ4L-a/jboss-eap-6.4.9-patch.zip?dl=1
ENV EAP_PATCH_2_URL=https://www.dropbox.com/sh/6nd9w26h8i9q7kj/AAD6e54V2-aGwVRtCRlB7oiba/jboss-eap-6.4.16-patch.zip?dl=1
ENV SSO_ADAPTER_URL=https://www.dropbox.com/sh/6nd9w26h8i9q7kj/AAAdK3duL06Tg5ncu4R_F1Nga/rh-sso-7.1.0-eap6-adapter.zip?dl=1

USER root
RUN yum -y install apr \
    && yum clean all

USER jboss
COPY support/installation-eap support/installation-eap.variables /opt/jboss/

RUN curl -O -J -L $EAP_INSTALLER_URL \
    && curl -O -J -L $EAP_PATCH_1_URL \
    && curl -O -J -L $EAP_PATCH_2_URL \
    && curl -O -J -L $SSO_ADAPTER_URL \
    && java -jar /opt/jboss/$EAP_INSTALLER  /opt/jboss/installation-eap -variablefile /opt/jboss/installation-eap.variables \
    && $JBOSS_HOME/bin/jboss-cli.sh --command="patch apply /opt/jboss/$EAP_PATCH_1 --override-all" \
    && $JBOSS_HOME/bin/jboss-cli.sh --command="patch apply /opt/jboss/$EAP_PATCH_2 --override-all" \
    && unzip -qo /opt/jboss/$SSO_ADAPTER  -d $JBOSS_HOME/ \
    && ($JBOSS_HOME/bin/standalone.sh & ) \
    && sleep 6 \
    && $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$JBOSS_HOME/bin/adapter-install.cli \
    && $JBOSS_HOME/bin/jboss-cli.sh --connect --command="/core-service=patching:ageout-history" \
    && kill -9 $(ps -c | grep java | cut -f3 -d" ") \
    && rm -rf /opt/jboss/$EAP_INSTALLER /opt/jboss/$EAP_PATCH_1 /opt/jboss/$EAP_PATCH_2 /opt/jboss/$SSO_ADAPTER /opt/jboss/installation-eap /opt/jboss/installation-eap.variables $JBOSS_HOME/standalone/configuration/standalone_xml_history \
    && rm -rf $JBOSS_HOME/.installation 


EXPOSE 9990 8080
VOLUME $JBOSS_HOME/standalone/logs

CMD ["/opt/jboss/jboss/bin/standalone.sh","-c","standalone.xml","-b", "0.0.0.0","-bmanagement","0.0.0.0"]
