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
