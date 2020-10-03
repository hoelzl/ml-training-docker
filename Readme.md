# ML-Training Docker Image

These files can be used to build a docker image that contains some useful 
machine learning libraries (in particular pytorch). By default the image
launches a jupyter notebook on port 8888 and expects a volume to be
mounted for `/root/python`.

To build the image you need to provide the following files:

    files/pkgs/*
    files/conda-env.list
    files/mycert.pem
    files/mykey.key

The file `conda-env.list` is a frozen conda environment, e.g., generated by

    conda list --explicit > conda-env.list

but typically modified to install from the local folder `/root/pkgs/`,
i.e., each entry should have the form

    file:///root/pkgs/blas-1.0-mkl.conda

The folder `files/pkgs/` has to contain all the files mentioned in
`conda-env.list`.

The certificates can be generated by the following command:

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout mykey.key -out mycert.pem


