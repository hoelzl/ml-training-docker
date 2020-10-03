FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive

ADD files/jupyter_notebook_config.py /root/.jupyter/
ADD files/miniconda.sh files/conda-env.list files/trains.conf files/mycert.pem files/mykey.key /root/
ADD files/pkgs/ /root/pkgs/

RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && apt-get -qq update \
    && bash /root/miniconda.sh -bfp /usr/local \
    && conda install --offline -y -c /root/pkgs/ --file=/root/conda-env.list \
    && rm -rf /root/miniconda.sh /root/conda-env.list /root/pkgs \
    && apt-get -qq -y --no-install-recommends install curl bzip2 gnupg ca-certificates wget git emacs-nox \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && conda clean --all --yes \
    && mkdir -p /root/python

ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
#     && wget -q https://nvidia.github.io/nvidia-docker/gpgkey \
#     && apt-key add gpgkey \
#     && rm -f gpgkey \
#     && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list \
#     && apt-get -qq update \
#     && apt-get -qq upgrade \
#     && apt-get -qq -y install nvidia-docker2 \
#     && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log

ENV PATH /opt/conda/bin:$PATH
VOLUME /root/python
WORKDIR /root/python
EXPOSE 8888/tcp

ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]

LABEL maintainer="Matthias Hölzl <tc@xantira.com>"
LABEL version="0.3"
