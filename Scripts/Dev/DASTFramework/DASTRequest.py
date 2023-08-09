#!/bin/python

import json
import veracode_api_py
from veracode_api_py import apihelper
import json
import csv
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()

# Dynamic request
request = ""

dynName = str()
bUID = str()
buEmail = str()
buOwner = str()
directoryRestrictionType = str()
httpAndHttps = bool(True)
blURL = str()
blackListItem = {
            "directory_restriction_type": directoryRestrictionType,
            "http_and_https": httpAndHttps,
            "url": blURL
          }

uaCustomHeader = str()
uaType = str("DEFAULT")
maxBrowsers = int(0)
similarityThreshold = int(0)
scannerVariables = {
      "reference_key": str(),
      "value": str(),
      "description": str()
    }
actionType = str("ADD")
scanID = str()
sciEmail = str()
firstAndLastName = str()
telephone = str()
alURL = str()
allowListItem = {
            "directory_restriction_type": directoryRestrictionType,
            "http_and_https": httpAndHttps,
            "url": alURL
          }
loginScriptBody = str()
logoutScriptBody = str()
header = {
            "key": str(),
            "value": str(),
            "url": str()
         }

dynScanConfigFull = {
  "name": dynName,
  "org_info": {
    "business_unit_id": bUID,
    "email": buEmail,
    "owner": buOwner
    },
  "scan_setting": {
    "blacklist_configuration": {
      "black_list": [ blackListItem ]
    },
    "user_agent": {
      "custom_header": uaCustomHeader,
      "type": uaType
    },
    "custom_hosts": [
      {
        "host_name": "my.custom.host",
        "ip_address": "127.0.0.1"
      }
    ],
    "max_browsers": maxBrowsers,
    "similarity_threshold": similarityThreshold
  },
  "scanner_variables": [ scannerVariables ],
  "scans": [
    {
      "action_type": actionType,
      "scan_id": scanID,
      "scan_contact_info": {
        "email": sciEmail,
        "first_and_last_name": firstAndLastName,
        "telephone": telephone
      },
      "scan_config_request": {
        "allowed_hosts": [ allowListItem ],
        "auth_configuration": {
          "authentications": {
            "AUTO": {
              "authtype": str(),
              "authentication_id": str(),
              "username": str(),
              "password": str()
            },
            "FORM": {
              "authtype": str(),
              "authentication_id": str(),
              "login_script_data": {
                "script_body": loginScriptBody,
                "script_type": "SELENIUM"
              },
              "logout_script_data": {
                "script_body": logoutScriptBody,
                "script_type": "SELENIUM"
              }
            },
            "BASIC": {
              "authtype": str(),
              "authentication_id": str(),
              "username": str(),
              "password": str(),
              "domain": str()
            },
            "CERT": {
              "authtype": str(),
              "authentication_id": str(),
              "password": str(),
              "base64_pkcs12": str(),
              "cert_name": str()
            },
            "HEADER": {
              "authtype": str(),
              "authentication_id": str(),
              "headers": [ header       
              ]
            },
            "OAUTH2": {
              "authtype": str(),
              "use_openid_connect": bool(True),
              "authentication_id": str(),
              "grant_type": "CLIENT_CREDENTIALS",
              "access_token_url": str(),
              "authorization_url": str(),
              "client_id": str(),
              "client_secret": str(),
              "username": str(),
              "password": str(),
              "redirect_url": str(),
              "scope": str(),
              "openid_url": str()
            },
            "JAVASCRIPT": {
              "authtype": str(),
              "authentication_id": str(),
              "base64_js": str(),
              "script_name": str()
            }
          }
        },
        "api_scan_setting": {
          "rate_limit_rps": 0,
          "spec_id": str()
        },
        "crawl_configuration": {
          "disabled": bool(False),
          "scripts": [
            {
              "crawl_script_data": {
                "script_body": str(),
                "script_type": "SELENIUM"
              },
              "crawl_script_id": str(),
              "number_scripts": 0
            }
          ]
        },
        "scan_setting": {
          "blacklist_configuration": {
            "black_list": [
              blackListItem
            ]
          },
          "user_agent": {
            "custom_header": str(),
            "type": str("DEFAULT")
          },
          "custom_hosts": [
            {
              "host_name": str("my.custom.host"),
              "ip_address": str("127.0.0.1")
            }
          ],
          "max_browsers": 0,
          "similarity_threshold": 0
        },
        "target_url": {
          "directory_restriction_type": directoryRestrictionType,
          "http_and_https": httpAndHttps,
          "url": str()
        },
        "scanner_variables": [
          {
            "reference_key": str(),
            "value": str(),
            "description": str()
          }
        ]
      },
      "linked_platform_app_uuid": str(),
      "internal_scan_configuration": {
        "enabled": bool(True),
        "endpoint_id": str(),
        "gateway_id": str()
      }
    }
  ],
  "schedule": {
    "duration": {
      "length": int(0),
      "unit": "DAY"
    },
    "effective_end_date": str(),
    "effective_start_date": str(),
    "end_date": str(),
    "now": bool(True),
    "scan_blackout_schedule": {
      "blackout_days": str(),
      "blackout_end_time": str(),
      "blackout_start_time": str(),
      "blackout_type": "THESE_HOURS"
    },
    "scan_recurrence_schedule": {
      "day_of_week": "MONDAY",
      "recurrence_interval": int(0),
      "recurrence_type": "MONTHLY",
      "schedule_end_after": int(0),
      "week_of_month": "FIRST"
    },
    "schedule_status": "ACTIVE",
    "start_date": str()
  },
  "special_instructions": str(),
  "visibility": {
    "setup_type": "SEC_LEADS_ONLY",
    "team_identifiers": [
      str()
    ]
  }
}



def FormatRequest():
  pass