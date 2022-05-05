FROM hashicorp/terraform

RUN apk add make

WORKDIR /tmp
COPY . /tmp

ENTRYPOINT [ "/usr/bin/make", "tfc" ]

FROM python:3

RUN pip3 install --extra-index-url https://pip.as-test.techservices.illinois.edu/index/test tflint

WORKDIR /tmp
COPY . /tmp

ENTRYPOINT [ "/usr/bin/make", "test" ]
