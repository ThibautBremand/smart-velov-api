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

## Running the API server
To run the server, simply run `npm start`.

By default, the server uses HTTPS protocol on the port 3000, but if you don't want to use HTTPS, set the environment variable `HTTPS` to `false`. In HTTP mode, the server uses the port 4000.

Don't forget to set the VELOV_API_KEY environment variable with your own key.

## API documentation

The API root is `http://aurelienbertron.fr/api/`

The API documentation is available at [http://docs.smartvelov.apiary.io/](http://docs.smartvelov.apiary.io/)
