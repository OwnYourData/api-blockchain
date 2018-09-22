FROM ruby:2.5.1
MAINTAINER "Christoph Fabianek" christoph@ownyourdata.eu

RUN mkdir -p /usr/src/app/merkle-hash-tree
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
COPY merkle-hash-tree /usr/src/app/merkle-hash-tree
COPY Gemfile /usr/src/app/
RUN gem install bundler builder git-version-bump && \
	cd merkle-hash-tree && \
	gem generate_index && \
	cd .. && \
	bundle install

COPY . .
RUN bundle update

CMD ["rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
