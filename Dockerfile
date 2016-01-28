FROM jdkizer9/python-w-build-tools
MAINTAINER James Kizer, Foundry @ Cornell Tech

RUN apt-get update

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

ADD ./requirements.txt requirements.txt

RUN virtualenv env

RUN . env/bin/activate

ENV RELIC_TAR_GZ_URL=https://github.com/cornelltech/relic/archive/master.tar.gz \
    PYRELIC_TAR_GZ_URL=https://github.com/cornelltech/pyrelic/archive/master.tar.gz \
    PYTHIA_TAR_GZ_URL=https://github.com/cornelltech/pythia/archive/master.tar.gz

WORKDIR /usr/src/app/relic

# Get RELIC toolkit and build

ADD $RELIC_TAR_GZ_URL ./master.tar.gz

RUN tar -xzvf master.tar.gz \
  &&  cp -a relic-master/. . \
  &&  rm -rf relic-master

## FIX NEEDED
## This preset builds relic w/ easy arith rather than gmp (suggested for pythia)
## figure out how to install gmp properly and use gmp
RUN ./preset/docker-x64.sh

RUN make all

WORKDIR /usr/src/app/pyrelic

# Get pyrelic

ADD $PYRELIC_TAR_GZ_URL ./master.tar.gz

RUN tar -xzvf master.tar.gz \
  &&  cp -a pyrelic-master/. . \
  &&  rm -rf pyrelic-master

WORKDIR /usr/src/app/pythia

# Get pythia

ADD $PYTHIA_TAR_GZ_URL ./master.tar.gz

RUN tar -xzvf master.tar.gz \
  &&  cp -a pythia-master/. . \
  &&  rm -rf pythia-master

WORKDIR /usr/src/app

# Install python packages required for pythia
RUN pip install -r ./pythia/requirements.txt

# Copy relic lib into pyrelic
RUN mkdir pyrelic/pyrelic/lib

RUN cp relic/lib/librelic.so pyrelic/pyrelic/lib

WORKDIR  /usr/src/app/pythia/django/pythiaPrfService

# Make pyrelic package available to pythia
RUN ln -s ../../../pyrelic/pyrelic/

WORKDIR /usr/src/app/pythia/django

ENV MONGODB_HOST=mongo \
    MONGODB_PORT=27017

EXPOSE 8000

## FIX NEEDED
## django cannot be used as a webserver in production.
## update to uWSGI
CMD ["python",  "manage.py",  "runserver", "0.0.0.0:8000"]
