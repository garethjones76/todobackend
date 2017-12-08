FROM gjones/todobackend-base:latest
MAINTAINER Gareth Jones <gareth_jones76@hotmail.com>

COPY target /wheelhouse

RUN . /appenv/bin/activate && \
    pip install --no-index -f /wheelhouse todobackend && \
    rm -rf /wheelhouse
    