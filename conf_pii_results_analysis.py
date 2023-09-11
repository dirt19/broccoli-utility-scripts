# ***************************************************************************
#
#         Date:  07-June-2023
#         License: Provided As-Is
#         Status: Active
#
# ***************************************************************************
# DESCRIPTION   : ***********************************************************
#                 This script is meant to analyze the Confluence PII scan results
#
# REQUIREMENTS  : ***********************************************************
#                 Confluence PII Scan Results CSV
#                 simple_keyring.py
#
# USAGE         : ***********************************************************
#                 CLI Usage: `python3 conf_pii_results_analysis.py`
#
# CODE REFERENCE: ***********************************************************
#                 Confluence: https://confluence/plugins/servlet/restbrowser#/resource/api-space/GET
# NOTES         : ***********************************************************
#
# ****************************************************************************
import pandas as pd
import requests
import warnings
warnings.filterwarnings('ignore', message='Unverified HTTPS request')

USERNAME = simple_keyring.get_item("username", "email")
TOKEN = simple_keyring.get_item(checkEnv, app, "identity_token")
URL = "https://confluence/rest/api/space"


# Get the desired statistices from the scan results
def get_conf_pii_results(file_path='confluence-pii-20230609-212202.csv'):
    df = pd.read_csv(file_path)
    
    # When was the most recent item scanned?
    df['Detection Time'] = pd.to_datetime(df['Detection Time'])
    most_recent_time = df['Detection Time'].max()

    # How many and which spaces have been scanned?
    spaces = df['Space'].value_counts().keys()

    return [most_recent_time, spaces]


# Query Confluence for all Spaces
def get_conf_spaces():
    auth = (USERNAME, TOKEN)
    headers = {'Content-Type': 'application/json'}
    start = 0
    limit = 25
    spaces = []
    while True:
        params = {
            "start": start,
            "limit": limit
        }
        response = requests.get(
            URL,
            auth = auth,
            params = params,
            headers = headers,
            verify = False
        )
        if response.status_code == 200:
            data = response.json()
            space_keys = [space['key'] for space in data['results']]
            spaces.extend(space_keys)
            if data['size'] < limit:
                break
            start += limit
        else:
            print("Error:", response.status_code)
            break
    return spaces


# Display the requested results
def run_analysis():
    # Using the scan results and the actual spaces on Confluence
    # Find the Spaces that have not been scanned
    conf_spaces = get_conf_spaces()
    scanned_spaces = get_conf_pii_results()
    unscanned = []
    for space in conf_spaces:
        if space not in scanned_spaces[1]:
            unscanned.append(space)
    
    scan_percentage = len(scanned_spaces[1])/len(conf_spaces) * 100
    
    print(f"""{'Total Confluence Spaces: ':<32} {len(conf_spaces):>3}
{'Total Spaces in Scan Results: ':<32} {len(scanned_spaces[1]):>3}
{'Spaces not in scan results: ':<32} {len(unscanned):>3}
{'Most recent item scanned: ':<32} {str(scanned_spaces[0]):>3}
{'PII Scan Coverage: ':<32} {scan_percentage:>3.2f}% """)


if __name__ == "__main__":
    run_analysis()