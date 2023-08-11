#!/usr/bin/env python3

import json

test_policy = open("test_policy_base.json", "r")
test_policy_base = json.load(test_policy)

# approved_sites = open("approved_sites.txt", "r")
# approved_site_list = approved_sites.read().splitlines()

# test_policy_base["URLAllowlist"] = approved_site_list

print(json.dumps(test_policy_base))
