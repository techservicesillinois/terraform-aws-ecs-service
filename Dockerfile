FROM hashicorp/terraform:0.12

RUN apk add make

WORKDIR /tmp
COPY . /tmp

ENTRYPOINT [ "/usr/bin/make", "tfc" ]

FROM python:3

RUN pip3 install --extra-index-url https://pip-test.techservices.illinois.edu/index/test tflint

WORKDIR /tmp
COPY . /tmp

ENTRYPOINT [ "/usr/bin/make", "test" ]
