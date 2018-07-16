FROM alpine:latest

VOLUME /site

EXPOSE 4000

WORKDIR /site

RUN apk update && \
    apk --update add \
    gcc \
    g++ \
    make \
    curl \
    bison \
    ca-certificates \
    tzdata \
    ruby \
    ruby-rdoc \
    ruby-irb \
    ruby-bundler \
    ruby-dev \
    glib-dev \
    libc-dev && \
    echo 'gem: --no-document' > /etc/gemrc && \
    gem install --no-ri --no-rdoc github-pages --version 188 && \
    gem install --no-ri --no-rdoc jekyll-watch && \
    gem install --no-ri --no-rdoc jekyll-admin && \
    apk del binutils bison perl nodejs curl && \
    rm -rf /var/cache/apk/*

CMD sh -c "bundle install && bundle exec jekyll serve -d /_site --watch --host 0.0.0.0 -P 4000"
