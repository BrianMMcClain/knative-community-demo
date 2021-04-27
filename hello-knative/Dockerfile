FROM ruby:2.7.2-alpine3.13

ADD . /hello-knative
WORKDIR /hello-knative
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "app.rb"]