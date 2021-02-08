# notejam
This document describes how to automatically deploy andy hyper-scale the notejam web application to Microsoft Azure.
The original project document can be found [here](https://github.com/t3ch-fr3ak/notejam/blob/master/README-original.rst).

## Business Requirements
- The Application must serve variable amount of traffic. Most users are active during business hours. During big
events and conferences the traffic could be 4 times more than typical.
- The Customer takes guarantee to preserve your notes up to 3 years and recover it if needed.
- The Customer ensures continuity in service in case of datacenter failures.
- The Service must be capable of being migrated to any regions supported by the cloud provider in case of
emergency.
- The Customer is planning to have more than 100 developers to work in this project who want to roll out
multiple deployments a day without interruption / downtime.
- The Customer wants to provision separated environments to support their development process for
development, testing, production in the near future.
- The Customer wants to see relevant metrics and logs from the infrastructure for quality assurance and
security purposes.

## Prepare Code
The following changes have been performed in the code:
1. Expose the python webserver by changing [runserver.py](https://github.com/t3ch-fr3ak/notejam/blob/master/flask/runserver.py)
2. Remove the HTTP protocol from CSS includes to support SSL in [templates/base.html](https://github.com/t3ch-fr3ak/notejam/blob/master/flask/notejam/templates/base.html)
3. Add PyMySQL for Azure MySQL support to [requirements.txt](https://github.com/t3ch-fr3ak/notejam/blob/master/flask/requirements.txt)

## Create Dockerfile
For reproducible and automatic deployment, the application is compiled, tested and deployed in a docker container. Therefore a [Dockerfile](https://github.com/t3ch-fr3ak/notejam/blob/master/Dockerfile) has been added with the following content:
```dockerfile
# get the base image
FROM alpine:3.5

# Install python and pip
RUN apk add --update py2-pip

# install Python modules needed by the Python app
COPY ./flask/requirements.txt /usr/src/app/requirements.txt
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt

# copy files required for the app to run
COPY ./flask /usr/src/app

# perform tests
RUN python /usr/src/app/tests.py

# tell the port number the container should expose
EXPOSE 5000

# run the application
CMD ["python", "/usr/src/app/runserver.py"]
```

## Architectural Overview
In order to cover all requirements, a scalable, highly available and easily deployable infrastructure has to be setup. Therefore the following components will be used:
- GitHub repository as source code control
- GitHub branching concept for continuous testing and continuous deployment in DEV
- GitHub actions as CI/CD pipeline for DEV and PRD environment
- Azure Container Registry as a docker image repository with versioning, backup and geo-replication
- Multiple Azure Web Apps (for geo-redundancy) as a docker host with application slots for DEV, INT and PRD. Application metrics and continuous deployment from the Azure Container Registry are configured and enabled
- Azure MySQL database instead of a SQLite3 database for concurrent usage and high availabilty using a replica database for geo-replication and automatic backups
- Azure Front Door as a single point of entry and load balancing between the multiple Azure Web App instances

## Azure Deployment
The deployment to Azure is fully automated using [ARM-Templates](https://github.com/t3ch-fr3ak/notejam/tree/master/ARM-Templates) and a bash script [deployment.sh](https://github.com/t3ch-fr3ak/notejam/blob/master/deployment.sh) using the Azure CLI.

As part of the infrastructure deployment, the docker container is already created and deployed to the Azure Web App. The script can be used as follows:

1. Login to Azure Shell [shell.azure.com/](http://shell.azure.com/)
1. Select Bash if not already selected
1. Clone this repository by running `git clone https://github.com/t3ch-fr3ak/notejam`
1. Navigate to the notejam folder by running `cd notejam`
1. Apply execute permissions by running `chown +x deployment.sh`
1. Start the deployment by running `./deployment.sh`

## CI/CD
For continuous deployment, 3 environments get created using Azure Web App Slots (DEV, INT, PRD). Each slot is configured for the corresponding docker image tagged DEV, INT or PRD. 
In order to deploy to any of these environments, 3 GitHub Actions Workflows have been created.

1. [deploy-prd.yml](https://github.com/t3ch-fr3ak/notejam/blob/master/.github/workflows/deploy-prd.yml): continuous deployment to the PRD container image for pushes and pull requests on the master branch only.
1. [deploy-int.yml](https://github.com/t3ch-fr3ak/notejam/blob/master/.github/workflows/deploy-int.yml): continuous deployment to the INT container image for pushes and pull requests on branches starting with **int/\***.
1. [deploy-dev.yml](https://github.com/t3ch-fr3ak/notejam/blob/master/.github/workflows/deploy-dev.yml): continuous deployment to the INT container image for pushes and pull requests on branches starting with **dev/\***.

Please ensure to update the container registry name in all 3 workflows according to the Azure Container Registry deployed before.
