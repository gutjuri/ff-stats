FROM ruby:2.5

WORKDIR /app

COPY Gemfile ./
RUN bundle install

