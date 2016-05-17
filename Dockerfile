FROM ubuntu:14.04
MAINTAINER Ram <ram@minewhat.com>
 

# Basic dependencies
RUN  apt-get update -qq \
  && apt-get install -y -qq \
      autoconf \
      imagemagick \
      curl \
      libcurl3 \
      libcurl3-dev \
  && apt-get clean -qq \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*





# NODE
# verify gpg and sha256: http://nodejs.org/dist/v0.10.31/SHASUMS256.txt.asc
# gpg: aka "Timothy J Fontaine (Work) <tj.fontaine@joyent.com>"
# gpg: aka "Julien Gilli <jgilli@fastmail.fm>"
RUN set -ex \
  && for key in \
    7937DFD2AB06298B2293C3187D33FF9D0246406D \
    114F43EE0176B71C7BC219DD50A3051F888C628D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 0.10.40
ENV NPM_VERSION 2.14.1

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
  && npm install -g npm@"$NPM_VERSION" \
  && npm cache clear





# RUBY 
ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.3

# Set $PATH so that non-login shells will see the Ruby binaries
ENV PATH $PATH:/opt/rubies/ruby-$RUBY_VERSION/bin

# Install MRI Ruby $RUBY_VERSION
RUN curl -O http://ftp.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz && \
    tar -zxvf ruby-$RUBY_VERSION.tar.gz && \
    cd ruby-$RUBY_VERSION && \
    ./configure --disable-install-doc && \
    make && \
    make install && \
    cd .. && \
    rm -r ruby-$RUBY_VERSION ruby-$RUBY_VERSION.tar.gz && \
    echo 'gem: --no-document' > /usr/local/etc/gemrc

# ==============================================================================
# Rubygems and Bundler
# ==============================================================================

ENV RUBYGEMS_MAJOR 2.3
ENV RUBYGEMS_VERSION 2.3.0

# Install rubygems and bundler
ADD http://production.cf.rubygems.org/rubygems/rubygems-$RUBYGEMS_VERSION.tgz /tmp/
RUN cd /tmp && \
    tar -zxf /tmp/rubygems-$RUBYGEMS_VERSION.tgz && \
    cd /tmp/rubygems-$RUBYGEMS_VERSION && \
    ruby setup.rb && \
    /bin/bash -l -c 'gem install bundler --no-rdoc --no-ri' && \
    echo "gem: --no-ri --no-rdoc" > ~/.gemrc






#PYTHON
# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

ENV PYTHON_VERSION 2.7.9

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF

RUN set -x \
  && mkdir -p /usr/src/python \
  && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
  && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
  && gpg --verify python.tar.xz.asc \
  && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
  && rm python.tar.xz* \
  && cd /usr/src/python \
  && ./configure --enable-shared \
  && make -j$(nproc) \
  && make install \
  && ldconfig \
  && curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
  && find /usr/local \
    \( -type d -a -name test -o -name tests \) \
    -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
    -exec rm -rf '{}' + \
  && rm -rf /usr/src/python

# Upgrade pip and install virtualenv
RUN  pip install -U pip \
  && pip install virtualenv


CMD ["bash"]


