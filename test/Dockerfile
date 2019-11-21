FROM python:3.5.2

ENV TERRAFORM_VERSION 0.11.8
ENV NODEJS_VERSION 8

RUN curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
    && apt-get install nodejs unzip \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g terraform-plan-parser \
    && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | \
       funzip - > /usr/local/bin/terraform \
    && chmod 755 /usr/local/bin/terraform \
    && pip install --extra-index-url https://pip-test.techservices.illinois.edu/index/test \
        sdg-test-behave-terraform

COPY . /usr/local/src

WORKDIR /usr/local/src/test

VOLUME /root/.aws

ENTRYPOINT ["behave", "--stop", "--no-capture"]
