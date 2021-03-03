FROM registry.cn-beijing.aliyuncs.com/tinet-hub/cticloud-tomcat:8.5 

RUN mkdir -p /usr/local/elk/logstash-5.6.3

ADD logstash-5.6.3/ /usr/local/elk/logstash-5.6.3/

RUN ls /usr/local/elk/logstash-5.6.3; \ 
    ls /usr/local/elk/logstash-5.6.3/config; \
    mkdir /usr/local/elk/logstash-5.6.3/conf ; 

 
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/elk/logstash-5.6.3/start.sh"]