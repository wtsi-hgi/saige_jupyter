# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 18.04 (bionic)
# https://hub.docker.com/_/ubuntu/?tab=tags&name=bionic
# OS/ARCH: linux/amd64
ARG ROOT_CONTAINER=ubuntu:bionic-20200311@sha256:e5dd9dbb37df5b731a6688fa49f4003359f6f126958c9c928f937bec69836320
ARG BASE_CONTAINER=$ROOT_CONTAINER
FROM $BASE_CONTAINER

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
# SAIGE dependencies
RUN apt-get update &&  \
    apt-get install mercurial curl make gcc g++ wget libxml2-dev cmake gfortran libreadline-dev \
    libz-dev libbz2-dev liblzma-dev libpcre3-dev libssl-dev libcurl4-openssl-dev \
    libopenblas-dev default-jre unzip libboost-all-dev \
    libpng-dev libcairo2-dev tabix  --yes && apt-get clean 
RUN apt-get install python3-pip --yes && pip3 install cget
RUN apt-get install python2.7 python-pip --yes

# extra R packages deps
RUN apt update && apt-get install -y \
    texlive-full texlive-xetex software-properties-common gfortran libudunits2-dev \
    libgdal-dev libgeos-dev libproj-dev libhdf5-dev    # ppa:ubuntugis/ubuntugis-unstable

RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR

RUN hg clone -r beta https://gavinband@bitbucket.org/gavinband/qctool && \
	cd qctool && \
	python2.7 ./waf-1.5.18 configure && \
	python2.7 ./waf-1.5.18 && \
        mv ./build/release/qctool* /usr/local/bin/ && \
        cd .. && rm -rf qctool && \
        chmod a+rwx /usr/local/bin/qctool*

RUN wget https://github.com/choishingwan/PRSice/releases/download/2.2.13/PRSice_linux.zip && \
	unzip PRSice_linux.zip && \
	rm PRSice_linux.zip && \
        mv PRSice* /usr/local/bin/ && \
        cd .. && rm -rf PRSice && \
        chmod a+rwx /usr/local/bin/PRSice*

USER $NB_UID
WORKDIR $HOME

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.8.2 \
    MINICONDA_MD5=87e77f097f6ebb5127c77662dfc3165e \
    CONDA_VERSION=4.8.2
    
RUN cd /tmp && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR

RUN conda config --system --prepend channels conda-forge && \
    conda config --system --append channels anaconda && \
    conda config --system --append channels r && \
    conda config --system --append channels bioconda && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda config --system --set channel_priority strict && \
    conda install --quiet --yes \
    'r-base=3.6.1' \
    'r-caret=6.0*' \
    'r-crayon=1.3*' \
    'r-devtools=2.2*' \
    'r-forecast=8.11*' \
    'r-hexbin=1.28*' \
    'r-htmltools=0.4*' \
    'r-htmlwidgets=1.5*' \
    'r-irkernel=1.1*' \
    'r-nycflights13=1.0*' \
    'r-plyr=1.8*' \
    'r-randomforest=4.6*' \
    'r-rcurl=1.98*' \
    'r-reshape2=1.4*' \
    'r-rmarkdown=2.1*' \
    'r-rodbc=1.3*' \
    'r-rsqlite=2.2*' \
    'r-shiny=1.4*' \
    'r-tidyverse=1.3*' \
    'unixodbc=2.3.*' \
    'notebook=6.0.3' \
    'jupyterhub=1.1.0' \
    r-e1071 \
    pip \
    'tini=0.18.0' \
    plink2 \
    bcftools \
    'jupyterlab=2.0.1' && \ 
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN pip install plinkio
RUN pip install ldpred

RUN conda config --system --prepend channels conda-forge && \
    conda config --system --append channels anaconda && \
    conda config --system --append channels r && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda config --system --set channel_priority flexible && \
    conda create -n py2.7 --quiet --yes \
    python=2.7 \
    r-essentials cmake gettext lapack r-matrix \
    r-rcpp r-rcpparmadillo r-data.table r-bh \
    r-spatest r-rcppeigen r-devtools r-skat \
    r-rcppparallel r-optparse boost openblas \
    'r-base=3.6.1' && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

RUN conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN ls -ltra $CONDA_DIR/envs/py2.7/bin/ && \
    echo old path is $PATH && \
    export PATH=$CONDA_DIR/envs/py2.7/bin:$PATH && \
    echo new path is $PATH &&\
    echo rscript.. $(which Rscript) && \
    FLAGPATH=`which python | sed 's|/bin/python$||'` && \
    export LDFLAGS="-L${FLAGPATH}/lib" && \
    export CPPFLAGS="-I${FLAGPATH}/include" && \
    export TAR="/bin/tar" && \
    Rscript -e 'devtools::install_github("weizhouUMICH/SAIGE")'

ENV PATH=$CONDA_DIR/bin:/opt/conda/envs/py2.7/bin:$PATH \
    R_LIBS_USER=/opt/conda/envs/py2.7/lib/R/library \
    R_LIBS=/opt/conda/envs/py2.7/lib/R/library

RUN wget https://cnsgenomics.com/software/gctb/download/gctb_2.0_Linux.zip && \
    unzip gctb_2.0_Linux.zip && \
    mv gctb_2.0_Linux/gctb $CONDA_DIR/bin/

COPY install_lassosum.R /usr/local/bin/
RUN Rscript /usr/local/bin/install_lassosum.R 

COPY install_packages.R /usr/local/bin/
RUN Rscript /usr/local/bin/install_packages.R 

EXPOSE 8080

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID

