# TODO: Extract this to bitnami/base-helm
FROM bitnami/minideb:stretch
LABEL maintainer "Bitnami <containers@bitnami.com>"

ENV HELM_VERSION="v2.11.0"
ENV CHART_VERSION="4.0.0"

# Install Helm, aws-cli and other utilities
RUN install_packages ca-certificates wget make jq python python-pip python-setuptools \
    && wget https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin \
    && rm -f /helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && pip install --upgrade awscli==1.16 \
    && apt-get remove -y python-pip python-setuptools

# Initialize Helm and download Wordpress Chart
RUN helm init -c

# Pull wordpress chart
# TODO: We might want to have the files baked in the repo, for now we do it this way to avoid duplication
RUN helm fetch stable/wordpress --version ${CHART_VERSION} \
		&& mkdir -p /cnab/app/charts/ && tar xzfv wordpress-${CHART_VERSION}.tgz -C /cnab/app/charts \
		&& rm wordpress-${CHART_VERSION}.tgz

COPY Dockerfile /cnab/Dockerfile
COPY app /cnab/app

CMD ["/cnab/app/run"]
