FROM ubuntu:14.04
MAINTAINER Andie Rabino <rabinoandie@gmail.com>

#
# Dockerfile to build latest OpenCV with Python2, Python3 and Java binding support.
#
FROM ubuntu:14.04
MAINTAINER Andie Rabino <rabinoandie@gmail.com>

#
# Utility "apt-fast" is installed by default just to accelerate installl progress.
# All other dependencies are more or less needed by building phase of OpenCV.
# The last "apt-get clean" command is needed to reduce Docker image size.
#
RUN apt-get update && apt-get upgrade -y \
&& apt-get install software-properties-common -y && add-apt-repository ppa:saiarcot895/myppa && apt-get update && apt-get -y install apt-fast \
&& apt-fast install -y \
build-essential cmake git pkg-config \
libgtk2.0-dev libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev \
python-dev python3.4-dev python3-numpy \
python-setuptools \
python3-matplotlib \
python3-scipy \
python3-skimage \
libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev \
libdc1394-22-dev libv4l-0 libv4l-dev libgl1-mesa-dev libgles1-mesa-dev libgles2-mesa-dev \
libopenvg1-mesa-dev libglu1-mesa-dev \
libgtkglext1 libgtkglext1-dev \
vtk6 libvtk6-dev \
libboost-python-dev \
&& apt-get clean

#
# Git clone the repo from OpenCV official repository on GitHub.
#
RUN mkdir /opt/opencv-build && cd /opt/opencv-build \
&& git clone https://github.com/Itseez/opencv && cd opencv \
&& git checkout master && mkdir build

WORKDIR /opt/opencv-build/opencv/build

#
# OpenCV repository is kept but all building intermediate files are removed.
# Installable path is set to "/opt".
#
# "FFMPEG" is an optional "I/O" part of OpenCV, since it generates a lot of
# error when building with it, it is disabled explicitly now.
#
# All other dependencies is using the default settings from CMake file of OpenCV.
#
RUN cmake -D CMAKE_BUILD_TYPE=Release -D WITH_FFMPEG=OFF -D WITH_1394=OFF -D CMAKE_INSTALL_PREFIX=/opt .. \
&& make -j2 && make install && make clean && cd .. && rm -rf build

#
# Let python(both v2 and v3) can find the newly install OpenCV modules.
#
RUN echo '/opt/lib/python3.4/dist-packages/'>/usr/lib/python3/dist-packages/cv2.pth

# Install latest cmake
RUN apt-fast install -y python3-pip && add-apt-repository ppa:george-edison55/cmake-3.x && apt-get update \
&& apt-get -y install cmake

# Install requirements
ADD requirements.txt /tmp/requirements.txt
RUN cd /tmp; pip3 install -r requirements.txt

# Install raven
RUN pip3 install raven
RUN pip3 install uwsgi
RUN pip3 install cython

ADD install_imagequant.sh /root/install_imagequant.sh
RUN chmod +x /root/install_imagequant.sh && /root/install_imagequant.sh

RUN pip3 install Pillow==3.4.2 --global-option="build_ext" --global-option="--enable-imagequant" -I

RUN add-apt-repository universe && apt-get update && apt-get install -y supervisor
RUN apt-get install -y autoconf
RUN git clone https://github.com/pornel/giflossy.git && cd giflossy  && autoreconf -i && \
 ./configure --disable-gifview && make install
RUN rm -rf giflossy

#install torch
WORKDIR /root/
RUN curl -s https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash -e
RUN git clone https://github.com/torch/distro.git ~/torch --recursive
WORKDIR torch
RUN ./install.sh && \
    cd install/bin && \
    ./luarocks install nn && \
    ./luarocks install dpnn && \
    ./luarocks install image && \
    ./luarocks install optim && \
    ./luarocks install csvigo && \
    ./luarocks install torchx && \
    ./luarocks install tds


RUN ln -s /root/torch/install/bin/* /usr/local/bin
#SETUP Openface
RUN pip3 install protobuf
RUN apt-get install -y \
    graphicsmagick \
    python3-pandas \
    wget \
    zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
WORKDIR /root/
RUN git clone https://github.com/cmusatyalab/openface.git
WORKDIR /root/openface/
RUN pip3 install helper
RUN pip3 install data
RUN python3 setup.py install #install openface
RUN pip3 install django-redis pyphen scikit-learn
RUN rm /usr/local/lib/python3.4/dist-packages/openface/torch_neural_net.py
RUN rm /root/openface/openface/torch_neural_net.py
ADD torch_neural_net.py /usr/local/lib/python3.4/dist-packages/openface/torch_neural_net.py
ADD torch_neural_net.py /root/openface/openface/torch_neural_net.py
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*
