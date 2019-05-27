FROM ubuntu:18.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install Python
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    curl \
    libbz2-dev \
    libffi-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    liblzma-dev \
    libncurses5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    psmisc \
    rsyslog \
    uuid-dev \
    vim \
    wget \
    zlib1g-dev && \
    wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz && \
    tar -xf Python-3.*.tar.xz && \
    cd Python-3.* && \
    ./configure && \
    make && \
    make install && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    python -m ensurepip && \
    ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
    cd .. && \
    rm -rf Python-3.* && \
    rm -rf Python-3.*.tar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use Bash as sh
RUN rm -rf /bin/sh && ln -s /bin/bash /bin/sh

ADD requirements.txt /var/docker/
RUN pip install -r /var/docker/requirements.txt

# Install Nginx
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libgd-dev \
    libgeoip-dev \
    libpcre3-dev \
    libxml2-dev \
    libxslt1-dev \
    unzip \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/
ADD Makefile /var/docker/nginx_src/
ADD ssl-bufsize.patch /var/docker/nginx_src/
RUN cd /var/docker/nginx_src/ && \
    make && \
    make install && \
    make clean
RUN mkdir -p /var/lib/nginx/
ADD nginx.conf /etc/nginx/

WORKDIR /srv/server

VOLUME /srv/server

CMD ["bash", "run.sh"]
