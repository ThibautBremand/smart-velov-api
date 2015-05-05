# smart-velov-api

## Prerequisites
- autotools
- curl
- osmosis

## Installation
```
git clone https://github.com/fat-gyft/smart-velov-api.git
cd smart-velov-api
git submodule init
git submodule update
```
Download and extract map for Lyon,FRANCE: `make map`

Run web server: `./run-web`

Clean only generated graph: `make clean`

Clean ALL maps: `make clean-map`

## Documentation de l'API

The API root is `http://aurelienbertron.fr/api/`

The API documentation is available at [http://docs.smartvelov.apiary.io/](http://docs.smartvelov.apiary.io/)
