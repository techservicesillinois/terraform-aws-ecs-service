FROM hashicorp/terraform as terraform

FROM python:3.8

RUN pip install --extra-index-url https://pip-test.techservices.illinois.edu/index/test \
        sdg-test-behave-terraform

COPY . /usr/local/src
COPY --from=terraform /bin/terraform /usr/local/bin/

WORKDIR /usr/local/src/test

VOLUME /root/.aws

CMD [ "--stop", "--no-capture", "-v", "-D", "log_level=DEBUG" ]
ENTRYPOINT [ "behave" ]