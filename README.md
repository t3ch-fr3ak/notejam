# notejam
Unified sample web app. The easy way to learn web frameworks.

This document describes how to automatically deploy andy hyper-scale the notejam web application to Microsoft Azure.
The original project document can be found [here](https://github.com/t3ch-fr3ak/notejam/blob/master/README-original.rst).

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
