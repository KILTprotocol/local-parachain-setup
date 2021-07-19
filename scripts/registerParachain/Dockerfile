FROM node:16.4.2-alpine

WORKDIR /app

COPY package.json package.json

COPY kilt.wasm kilt.wasm
COPY kilt-genesis.hex kilt-genesis.hex

COPY . .
RUN yarn install