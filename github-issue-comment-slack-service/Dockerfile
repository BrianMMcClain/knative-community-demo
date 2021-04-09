FROM ruby:2.7.2-alpine3.13

RUN apk update \
    && apk --no-cache --update add build-base 

ADD . /github-issue-comment-slack-service
WORKDIR /github-issue-comment-slack-service
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "app.rb"]