FROM bitnami/kubectl
USER root
RUN apt-get update && apt-get upgrade && apt-get install jq -y && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives
COPY updateConfigMap.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/updateConfigMap.sh" ]
USER 1001