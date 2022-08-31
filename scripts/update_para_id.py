import os
import json
import sys


if __name__ == "__main__":
    input_file = sys.argv[1]
    new_paraid = int(sys.argv[2])

    with open(input_file, "r") as f:
        input_json = json.load(f)

    if "raw" in input_json["genesis"] and input_json["para_id"] == new_paraid:
        print("All good para ID is correct.")
        sys.exit(0)
    elif "raw" in input_json["genesis"]:
        print("ERROR. Wrong paraID but raw spec can't be updated")
        sys.exit(1)

    input_json["para_id"] = new_paraid
    input_json["genesis"]["runtime"]["parachainInfo"]["parachainId"] = new_paraid
    input_json["bootNodes"] = []

    with open(input_file, "w") as f:
        json.dump(input_json, f, indent=2)
