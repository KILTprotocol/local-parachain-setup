# How to setup Parachain

## install dependencies

The scripts need the master version of jq (with big int support) and sponge.

```
brew install --HEAD jq
brew install sponge
```

## setup

- generate genesis
- build wasm
- update rococo and parachain spec

## register

- register parachain: Network > Parachains > Parathreads -> `+ Register`
- Sudo > slots > forceLease
