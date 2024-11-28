FROM alpine/helm:3.14.2

ARG KUBECTL_VERSION="v1.30.7"

RUN apk add --no-cache curl && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

COPY hack/cni-install.sh /scripts/install.sh
RUN chmod +x /scripts/install.sh