ARG ALPINE_IMAGE=alpine:3.8@sha256:621c2f39f8133acb8e64023a94dbdf0d5ca81896102b9e57c0dc184cadaf5528

FROM ${ALPINE_IMAGE} AS build

ENV UPX_UCLDIR=/usr/src/ucl

RUN apk --update-cache upgrade && apk add \
        bash \
        build-base \
        git \
        perl \
        zlib-dev

RUN git clone https://github.com/upx/upx.git
RUN wget https://www.oberhumer.com/opensource/ucl/download/ucl-1.03.tar.gz -O ucl-1.03.tar.gz

WORKDIR ${UPX_UCLDIR}

COPY config.cache .

RUN tar -xf /ucl-1.03.tar.gz --strip-components=1
RUN ./configure -q -C "CC=gcc -std=gnu89" && make

WORKDIR /upx

# LZMA SDK
RUN git submodule update --init --recursive

RUN make all


FROM ${ALPINE_IMAGE}

ONBUILD RUN apk --update-cache upgrade

COPY --from=build /upx/src/upx.out /bin/upx
COPY --from=build /var/cache/apk /var/cache/apk

RUN apk add \
        build-base \
        xz \
    && rm -rf /var/cache/apk/*

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
      description="Alpine base image with build tools available" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URLs
