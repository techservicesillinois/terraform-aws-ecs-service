Set up Docker on a Windows 10 machine using the WSL.

# Set up and Install Software on Windows Machine:

## WSL:

Enable WSL in Powershell (Run as Administrator):
    
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

RESTART COMPUTER: You cannot install a WSL application until after Windows is restarted.

Install WSL of choice (**Ubuntu**/Debian) from Windows Store
	
## Docker for Windows (DfW):

### Install:

https://docs.docker.com/v17.09/docker-for-windows/install/

### Configure:

#### General:

Check ALL boxes on this page, but the most important one is "Expose daemon on tcp://localhost:2375 without TLS"

(This will allow you to run the Docker CLI in the WSL by connecting to the DfW server)

#### Shared Drives:

Check "C" (at least)

(This will allow for Dockerfile VOLUMEs)

# Set up and Install Software on WSL:

Edit `/etc/wsl.conf`:

```
[automount]
root = /
options = "metadata"
```

This configuration allows for the `/mnt/c/.../` path to be mirrored with a `/c/.../` alias. Docker expects filepaths of the latter type generally, and it looks cleaner.

RESTART COMPUTER: The `wsl.conf` will not make changes to WSL instances until you restart the computer.

## Add the following to ~/.bashrc:
		
`export DOCKER_HOST="tcp://0.0.0.0:2375"`

### Install Docker within WSL:

#### Basic Setup:

```
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
```

#### Add Docker's offical GPG key:
			
`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -`
		
#### Pick a Release Channel:
			
```
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt-get update
```

#### Install the Latest Version of Docker CE:
			
`sudo apt-get install -y docker-ce`
		
#### Allow Your User to Access the Docker CLI without Needing Root:

`sudo usermod -aG docker $USER`

### Install pip:

```
sudo apt-get update
sudo apt-get install python3-pip
pip3 install --upgrade pip
```

### Install awscli-login:

```
pip3 install awscli-login
aws configure set plugins.login awscli_login
```

Now, create a folder on your Windows system at the location below. It's easiest to navigate to the location using the
**File Explorer** Application and right-clicking to create a new folder.

  `C:\\Users\${USER}\.aws`

Finally, create a symlink to this folder within the WSL home directory:

```
cd ~/
ln -ls /c/Users/${USER}/.aws .
```

This will allow the necessary Docker VOLUME to work when running Behave Terraform tests where we need aws credentials.
Docker VOLUMEs do not work with the WSL file system, but they do work with the Windows file system, so this work-around
will be needed for any VOLUMEs that are needed.

Thankfully, the COPY keyword in Dockerfiles works just fine with WSL, so no work-around is needed for that.

### Configure awscli-login:

```
aws login configure
...
aws login
...
```

After logging into to AWS, your credentials will be stored in the `~/.aws` directory, which you'll remember is a symlink to a folder on the Windows file system.

## Running Docker:

Using the Example files below, run a Docker container. The Makefile
makes it easier to run common commands without having to memorize
as much.

### Commands:

**$ make build**

  This command will need to be run whenever there is a change
  in the:
  
  - code base
  - tests (e.g. Behave features, unittest python modules)
  - Dockerfile (rare, unless actively developing)

**$ make behave**

  This command will spin up a Docker container, run the Behave
  tests, and then delete itself.

**$ make debug**

  This command will spin up a Docker container and initialize
  it with a shell so that the developer/tester can poke around in the
  container environment.

# Example Files:

## Example Dockerfile:

```
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
```

## Example Makefile (Edited for Length):

```
CONTAINER := terraform_modules_test

# Code Snippet Source: (Used to run in WSL or Unix-based system seemlessly)
#	https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
ifneq ($(shell grep -cE "(Microsoft|WSL)" /proc/version 2>/dev/null || echo 0), 0)
    HOME := /c/Users/$(USER)
endif

behave:
    docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm $(CONTAINER)

debug:
    docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm --entrypoint bash $(CONTAINER)

build:
    docker build . -t $(CONTAINER)

clean: 
    docker rmi $(CONTAINER)
```

# Resources

https://docs.microsoft.com/en-us/windows/wsl/install-win10

https://github.com/evanjtravis/as-aws-modules/blob/feature/ejtravis/ecr-test/Dockerfile

https://github.com/evanjtravis/as-aws-modules/blob/feature/ejtravis/ecr-test/Makefile

https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/

https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly
