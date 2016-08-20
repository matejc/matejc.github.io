FROM ruby:2.3-alpine

RUN apk add --update build-base

RUN mkdir -p /usr/src/app
COPY Gemfile /usr/src/app/
WORKDIR /usr/src/app

RUN bundle install

CMD bundler exec jekyll serve -d /_site --watch --force_polling -H 0.0.0.0 -P 4000
