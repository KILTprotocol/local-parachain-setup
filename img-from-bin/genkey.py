#!/usr/bin/env python3
"""
Setup the keystore folder.

requires atleast python 3.6
"""
import argparse
import binascii
import json
import pathlib
import re
import shutil
import subprocess
import typing

HEX_GRAN = binascii.hexlify(b"gran").decode("UTF-8")
HEX_BABE = binascii.hexlify(b"babe").decode("UTF-8")
HEX_IMON = binascii.hexlify(b"imon").decode("UTF-8")
HEX_PARA = binascii.hexlify(b"para").decode("UTF-8")
HEX_AUDI = binascii.hexlify(b"audi").decode("UTF-8")
HEX_AURA = binascii.hexlify(b"aura").decode("UTF-8")


def subkey_inspect(subkey_bin, uri, scheme) -> typing.Dict[str, str]:
    cmd = [subkey_bin, "inspect", "--scheme", scheme, "--output-type", "json",
           uri]
    result = subprocess.run(cmd, check=True, capture_output=True)
    try:
        return json.loads(result.stdout)
    except json.decoder.JSONDecodeError as err:
        print(f"Error while parsing output! ({err})")
        print("command: ({})".format(" ".join(cmd)))
        print(f"Output: ({result.stdout})")
        raise RuntimeError("invalid output from subkey") from err


def write_session_keys(seed: str, outdir: pathlib.Path, key_ed: typing.Optional[str], key_sr: typing.Optional[str]):
    stripped_seed = re.sub(r"^0x", "", seed)
    prefixed_seed = "0x" + stripped_seed

        # get public keys either using subkey or the supplied arguments
    if key_ed is None:
        key_info = subkey_inspect(subkey_is_installed, prefixed_seed, "Ed25519")
        key_ed = key_info["publicKey"]

    if key_sr is None:
        key_info = subkey_inspect(subkey_is_installed, prefixed_seed, "Sr25519")
        key_sr = key_info["publicKey"]

    key_ed = re.sub(r"^0x", "", key_ed)
    key_sr = re.sub(r"^0x", "", key_sr)

    filepaths = [
        outdir / (HEX_GRAN + key_ed),
        outdir / (HEX_AURA + key_ed),
        outdir / (HEX_AURA + key_sr),
        outdir / (HEX_BABE + key_sr),
        outdir / (HEX_IMON + key_sr),
        outdir / (HEX_PARA + key_sr),
        outdir / (HEX_AUDI + key_sr),
    ]

    for path in filepaths:
        print(f"Write session key: {path.name}")
        with path.open("w") as f:
            f.write(f'"0x{stripped_seed}"')


if __name__ == "__main__":
    subkey_is_installed = shutil.which("subkey")
    if subkey_is_installed:
        print("subkey installation found.")

    # Create Parser
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", "-s", required=True, nargs="+",
                        help="The secret seed for the controller account")
    parser.add_argument("--ed," "--public-key-ed25519", required=not subkey_is_installed,
                        help="The public key of the node (Ed25519 / optional if subkey is installed)", dest="key_ed")
    parser.add_argument("--sr," "--public-key-sr25519", required=not subkey_is_installed,
                        help="The public key of the node (Sr25519 / optional if subkey is installed)", dest="key_sr")
    parser.add_argument("-o," "--out-dir",
                        help="Directory where key-files will be stored (will be created of not existing)",
                        default="keystore", dest="out_dir")

    # Read args from cli
    args = parser.parse_args()

    keypath = pathlib.Path(args.out_dir)
    keypath.mkdir(exist_ok=True)

    for seed in args.seed:
        for s in seed.split():
            write_session_keys(s, keypath, args.key_ed, args.key_sr)
