FROM ruby:2.2.2
RUN apt-get update -qq && apt-get install -y build-essential &&\
    apt-get install -y sqlite3 libsqlite3-dev && \
    apt-get install -y libxml2-dev libxslt1-dev && \
    apt-get install -y nodejs &&\
    apt-get clean

ADD Gemfile /opt/server/Gemfile
RUN cd /opt/server && bundle install
Add . /opt/server

WORKDIR /opt/server

# Setup rails with actioncable
RUN ./bin/setup

ENTRYPOINT ["/opt/server/bin/run_all.sh"]