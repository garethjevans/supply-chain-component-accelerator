FROM harbor-repo.vmware.com/dockerhub-proxy-cache/library/ubuntu:jammy

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y jq curl git ca-certificates gnutls-bin && \
    rm -rf /var/lib/apt/lists/*

ARG IMGPKG_VERSION=0.37.2
RUN url=https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/v${IMGPKG_VERSION}/imgpkg-linux-amd64; \
    curl -sSL $url -o /usr/local/bin/imgpkg && \
    chmod +x /usr/local/bin/imgpkg

ARG KBLD_VERSION=0.37.4
RUN url=https://github.com/vmware-tanzu/carvel-kbld/releases/download/v${KBLD_VERSION}/kbld-linux-amd64; \
    curl -sSL $url -o /usr/local/bin/kbld && \
    chmod +x /usr/local/bin/kbld

ARG ytt_VERSION=0.45.3
RUN url=https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${ytt_VERSION}/ytt-linux-amd64; \
    curl -sSL $url -o /usr/local/bin/ytt && \
    chmod +x /usr/local/bin/ytt

ARG CRANE_VERSION=0.14.0
RUN curl -sL "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" > go-containerregistry.tar.gz && \
	tar -zxvf go-containerregistry.tar.gz -C /usr/local/bin/ crane && \
	chmod +x /usr/local/bin/crane

