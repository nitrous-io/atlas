FROM ruby:2.2.2

ADD Gemfile /opt/websocket-server/Gemfile
WORKDIR /opt/websocket-server

RUN bundle install
ADD server.rb /opt/websocket-server/server.rb

ENTRYPOINT ["bundle", "exec", "ruby", "server.rb"]