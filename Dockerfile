FROM ruby:2.5.1
MAINTAINER "Christoph Fabianek" christoph@ownyourdata.eu

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		postgresql \
		postgresql-contrib \
		libpq-dev \
		libsodium-dev && \
	rm -rf /var/lib/apt/lists/*

ENV RAILS_ROOT $WORKDIR
COPY Gemfile /usr/src/app/

RUN bundle install
RUN gem install bundler

COPY . .

RUN bundle update

CMD ["rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
