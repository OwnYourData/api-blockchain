FROM ruby:2.5.3
MAINTAINER "Christoph Fabianek" christoph@ownyourdata.eu

RUN mkdir -p /usr/src/app/merkle-hash-tree
WORKDIR /usr/src/app

RUN echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		postgresql \
		postgresql-contrib \
		libpq-dev \
		libsodium-dev=1.0.17-1~bpo9+1 && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
