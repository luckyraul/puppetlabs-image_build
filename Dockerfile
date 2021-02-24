FROM debian:buster

MAINTAINER Nikita Tarasov <nikita@mygento.ru>

RUN apt-get -qq update && \
    apt-get -qqy install gnupg curl git sudo procps && \
    gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -c "source /etc/profile.d/rvm.sh" && \
    rvm install ruby-2.7.2 && \
    rvm --default use ruby-2.7.2 && \
    sudo gem install puppet --no-document -v '~> 6.18.0' && \
    sudo rm -fR /etc/puppetlabs/code/modules/image_build && \
    sudo git clone --single-branch --branch v2 https://github.com/luckyraul/puppetlabs-image_build.git /etc/puppetlabs/code/modules/image_build
