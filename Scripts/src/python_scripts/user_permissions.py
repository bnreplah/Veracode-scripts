# TODO: Modify the script to be able to extract more data when using the operator api credentials

import sys
import requests
import json
import getopt
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC
import xml.etree.ElementTree as ET  # for parsing XML

from veracode_api_signing.credentials import get_credentials


json_headers = {
    "User-Agent": "User permissions reader - python script",
    "Content-Type": "application/json"
}

def print_teams(teams):
    print("Teams: ")
    for index in range(len(teams)):
        print(f"  - {teams[index]['team_name']}")
    print("------------------------")

def print_roles(roles):
    print("Roles: ")
    for index in range(len(roles)):
        print(f"  - {roles[index]['role_name']}")
    print("------------------------")

def read_user_permissions(api_base, verbose):
    global failed_attempts
    global sleep_time
    global max_attempts_per_request
    path = f"{api_base}api/authn/v2/users/self"
    if (verbose):
        print(f"Calling: {path}")

    response = requests.get(path, auth=RequestsAuthPluginVeracodeHMAC(), headers=json_headers)
    data = response.json()

    if response.status_code == 200:
        if (verbose):
            print(data)
        print (f"User Name: {data['user_name']}")
        print (f"First Name: {data['first_name']}")
        print (f"Last Name: {data['last_name']}")
        print (f"Email: {data['email_address']}")
        print_teams(data["teams"])
        print_roles(data["roles"])

    else:
        print(f"ERROR: code: {response.status_code}")
        print(f"ERROR: value: {data}")

def get_api_base():
    api_key_id, api_key_secret = get_credentials()
    api_base = "https://api.veracode.{instance}/"
    if api_key_id.startswith("vera01"):
        return api_base.replace("{instance}", "eu", 1)
    else:
        return api_base.replace("{instance}", "com", 1)

def main(argv):
    """Allows for bulk adding application profiles"""
    verbose = False    
    try:
        opts, args = getopt.getopt(argv, "d", [])
        for opt, arg in opts:
            if opt == '-d':
                verbose = True
        read_user_permissions(get_api_base(), verbose)
    except requests.RequestException as e:
        print("An error occurred!")
        print(e)
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
