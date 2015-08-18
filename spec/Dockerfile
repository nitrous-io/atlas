FROM ruby:2.2.2

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends --fix-missing \
    curl perl make build-essential procps dnsmasq vim \
    && rm -rf /var/lib/apt/lists/*

RUN gem install rspec -v "3.3.0" \
    && gem install rest-client -v "2.0.0.rc1" \
    && gem install faye-websocket -v "0.10.0"

WORKDIR /opt/test