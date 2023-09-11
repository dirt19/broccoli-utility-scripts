import requests
from pprint import pprint
import warnings
warnings.filterwarnings('ignore', message='Unverified HTTPS request')

jwtToken = "ToBePopulated"
email = "user@domain.com"
mendUserKey = "<the long hex key>"
MendOrgToken = "<the Mend org otken>"

apiurl="https://api-saas.whitesourcesoftware.com/api/v2.0/"
endpoint="login"
headers={'Content-Type': 'application/json'}
data={
    'email': email,
    'userKey': mendUserKey,
    'orgToken': MendOrgToken
    }
response = requests.post(
        url=apiurl+endpoint,
        headers=headers,
        json=data,
        verify=False)
if response.ok:
    data=response.json()
    jwtToken = data['retVal']['jwtToken']


product = <mend product token>"
auth = {'Authorization': 'Bearer ' + jwtToken}
response = requests.get(
    f"{apiurl}products/{product}/libraries", 
    headers = auth,
    verify=False)

print(response.text)