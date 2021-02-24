FROM debian:bullseye

MAINTAINER Nikita Tarasov <nikita@mygento.ru>

RUN apt-get -qq update && \
    apt-get -qqy install git ruby sudo && \
    sudo gem install puppet --no-document -v '~> 6.18.0' && \
    sudo rm -fR /etc/puppetlabs/code/modules/image_build && \
    sudo git clone --single-branch --branch v2 https://github.com/luckyraul/puppetlabs-image_build.git /etc/puppetlabs/code/modules/image_build
