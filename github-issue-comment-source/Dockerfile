FROM ruby:2.7.2-alpine3.13

ADD . /github-issue-comment-source
WORKDIR /github-issue-comment-source
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "github-issue-comment-source.rb"]