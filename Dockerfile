####
# Description:
# Steps:

FROM ubuntu:14.04

#### environment variables
ENV OPENCV_VERSION 2.4.9
ENV THRIFT_VERSION 0.9.2
ENV THREADS 4
ENV PROTOBUF_VERSION 2.5.0
ENV LD_LIBRARY_PATH /usr/local/lib

#### common package installations
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y software-properties-common 
RUN apt-get install -y gfortran
RUN apt-get install -y make
RUN apt-get install -y ant
RUN apt-get install -y gcc
RUN apt-get install -y g++
RUN apt-get install -y wget
RUN apt-get install -y automake
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y libboost-all-dev
RUN apt-get install -y libevent-dev
RUN apt-get install -y libtool
RUN apt-get install -y pkg-config
RUN apt-get install -y libtesseract-dev
RUN apt-get install -y libopenblas-dev
RUN apt-get install -y libblas-dev
RUN apt-get install -y libatlas-dev
RUN apt-get install -y libatlas-base-dev
RUN apt-get install -y liblapack-dev
RUN apt-get install -y cmake
RUN apt-get install -y zip
RUN apt-get install -y unzip
RUN apt-get install -y sox
RUN apt-get install -y libsox-dev
RUN apt-get install -y autoconf
RUN apt-get install -y bison
RUN apt-get install -y swig
RUN apt-get install -y python-pip
RUN apt-get install -y subversion
RUN apt-get install -y libssl-dev
RUN apt-get install -y libprotoc-dev

#### package specific routines
ENV JAVA_VERSION 7
RUN \
  echo oracle-java$JAVA_VERSION-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java$JAVA_VERSION-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk$JAVA_VERSION-installer

#### Thrift
RUN cd /usr/src \
 && wget "http://archive.apache.org/dist/thrift/$THRIFT_VERSION/thrift-$THRIFT_VERSION.tar.gz" \
 && tar xf thrift-$THRIFT_VERSION.tar.gz \
 && cd thrift-$THRIFT_VERSION \
 && ./configure \
 && make -j $THREADS\
 && make -j $THREADS install \
 && cd lib/py/ \
 && python setup.py install \
 && cd ../../lib/java/ \
 && ant \
 && cd ../../..

#### OpenCV
RUN mkdir -p /usr/src/opencv
RUN cd /usr/src/opencv \
  && git clone https://github.com/Itseez/opencv.git opencv-$OPENCV_VERSION \
  && cd opencv-$OPENCV_VERSION \
  && git checkout $OPENCV_VERSION \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make -j$THREADS \
  && make -j$THREADS install

#### Protobuf
RUN mkdir -p /usr/src/protobuf
RUN cd /usr/src/protobuf \
  && wget "https://github.com/google/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-$PROTOBUF_VERSION.tar.gz" \
  && tar xf protobuf-$PROTOBUF_VERSION.tar.gz \
  && cd protobuf-$PROTOBUF_VERSION \
  && ./configure \
  && make -j$THREADS \
  && make install

#### Caffe for djinn
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
RUN apt-get install -y libleveldb-dev libsnappy-dev libhdf5-serial-dev
RUN apt-get install -y bc
RUN apt-get install -y python-numpy
ENV CPU_ONLY 1

RUN cd /usr/src \
  && git clone https://github.com/jhauswald/caffe.git \
  && cd caffe \
  && git checkout ipa \
  && cp Makefile.config.example Makefile.config \
  && make -j$THREADS \
  && make distribute

RUN apt-get install -y supervisor
RUN apt-get install -y flac
RUN apt-get install -y gawk
RUN apt-get install -y imagemagick

## install lucida
# fixes some weird OE compiliation issue
ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 
ENV THRIFT_ROOT /usr/src/thrift-$THRIFT_VERSION
ENV CAFFE /usr/src/caffe/distribute
ENV LUCIDAROOT /usr/local/lucida/lucida
RUN mkdir -p /usr/local/lucida
WORKDIR /usr/local/lucida
ADD . /usr/local/lucida
RUN cd lucida/ && ./thrift-gen.sh
RUN /usr/bin/make all
