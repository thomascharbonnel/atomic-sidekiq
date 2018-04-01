# Choose the official Ruby 2.3.4 image as our starting point
FROM ruby:2.5.1

ENV LC_ALL en_US.UTF-8

# install locked bundler version (1.16.1)
RUN gem install bundler -v 1.16.1
ENV BUNDLE_PATH=/bundle BUNDLE_JOBS=4

# Set up working directory
ENV APP_HOME /sidekiq-atomic

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile .
ADD Gemfile.lock .

RUN bundle install

ADD . $APP_HOME
