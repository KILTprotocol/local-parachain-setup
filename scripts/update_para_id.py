import os
import json
import sys


if __name__ == "__main__":
    input_file = sys.argv[1]
    new_paraid = int(sys.argv[2])

    with open(input_file, "r") as f:
        input_json = json.load(f)

    input_json["para_id"] = new_paraid
    input_json["genesis"]["runtime"]["parachainInfo"]["parachainId"] = new_paraid
    input_json["bootNodes"] = []

    with open(input_file, "w") as f:
        json.dump(input_json, f, indent=2)
