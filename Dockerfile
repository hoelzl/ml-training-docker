FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive

ADD files/jupyter_notebook_config.py /root/.jupyter/
ADD files/miniconda.sh files/conda-env.list files/trains.conf files/mycert.pem files/mykey.key /root/
ADD files/pkgs/ /root/pkgs/

RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && apt-get -qq update \
    && apt-get -qq -y --no-install-recommends install curl bzip2 gnupg ca-certificates wget git less emacs-nox \
    && apt-get -qq -y autoremove \
    && apt-get autoclean

RUN bash /root/miniconda.sh -bfp /usr/local \
    && conda update conda \
    && conda install -y -c /root/pkgs/ --file=/root/conda-env.list \
    && conda clean --all --yes \
    && rm -rf /root/miniconda.sh /root/conda-env.list /root/pkgs \
    && mkdir -p /root/python

ENV PATH /opt/conda/bin:$PATH

RUN pip install datasets tokenizers trains trains-agent

# ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
#     && wget -q https://nvidia.github.io/nvidia-docker/gpgkey \
#     && apt-key add gpgkey \
#     && rm -f gpgkey \
#     && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list \
#     && apt-get -qq update \
#     && apt-get -qq upgrade \
#     && apt-get -qq -y install nvidia-docker2 \
#     && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log

VOLUME /root/python
WORKDIR /root/python
EXPOSE 443/tcp

ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
RUN conda init --all
RUN  echo y | jupyter kernelspec uninstall python3 \
    && python -m ipykernel install --user --name base --display-name "Python (base)"
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]

LABEL maintainer="Matthias Hölzl <tc@xantira.com>"
LABEL version="0.7"
