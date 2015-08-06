FROM ruby:2.2.2
RUN apt-get update -qq && apt-get install -y build-essential &&\
    apt-get install -y sqlite3 libsqlite3-dev && \
    apt-get install -y libxml2-dev libxslt1-dev && \
    apt-get install -y nodejs &&\
    apt-get clean

# install redis
RUN wget http://download.redis.io/releases/redis-3.0.3.tar.gz -P /tmp/ \
  && tar xzf /tmp/redis-3.0.3.tar.gz -C /tmp/ \
  && cd /tmp/redis-3.0.3 \
  && make \
  && make install \
  && /tmp/redis-3.0.3/utils/install_server.sh \
  && service redis_6379 stop \
  && rm -rf /tmp/redis-3.0.3 /tmp/redis-3.0.3.tar.gz

ADD . /opt/server
WORKDIR /opt/server

# Setup
RUN bundle install

# Setup rails with actioncable
RUN ./bin/setup

ENTRYPOINT ["/opt/server/bin/run_all.sh"]