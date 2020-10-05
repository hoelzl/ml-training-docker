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
    && mkdir -p /root/pkgs \
    && conda install -c fastai -c pytorch -c conda-forge -y --file=/root/conda-env.list \
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

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.2.89
ENV CUDA_PKG_VERSION 10-2=$CUDA_VERSION-1

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-$CUDA_PKG_VERSION \
    cuda-compat-10-2 \
    && ln -s cuda-10.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.2 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"


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
