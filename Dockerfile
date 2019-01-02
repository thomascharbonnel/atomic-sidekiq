# Choose the official Ruby 2.3.4 image as our starting point
FROM ruby:2.5.1

# Run updates
RUN apt-get update -qq && apt-get install -y build-essential locales chromedriver

ENV DEBIAN_FRONTEND noninteractive
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_US.UTF-8

# install locked bundler version (1.16.4)
RUN gem install bundler -v 1.16.4
ENV BUNDLE_PATH=/bundle BUNDLE_JOBS=4

# Set up working directory
ENV APP_HOME /sidekiq-atomic

RUN mkdir $APP_HOME
ADD . $APP_HOME

WORKDIR $APP_HOME

RUN bundle install
