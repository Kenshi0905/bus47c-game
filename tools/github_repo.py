"""Create a private GitHub repository using Git's configured credential helper.
Credentials stay in memory and are never printed or written to this repository.
"""
import subprocess, urllib.request, urllib.error, json, os
os.environ['GIT_TERMINAL_PROMPT']='0'
r=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True)
creds=dict(line.split('=',1) for line in r.stdout.splitlines() if '=' in line)
token=creds.get('password')
if not token:
 print('NO_STORED_GITHUB_CREDENTIAL');raise SystemExit(2)
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','User-Agent':'Bus47C-setup','X-GitHub-Api-Version':'2022-11-28'}
def request(path,data=None):
 req=urllib.request.Request('https://api.github.com'+path,headers=headers,data=json.dumps(data).encode() if data is not None else None)
 with urllib.request.urlopen(req,timeout=30) as f:return json.load(f)
try:
 profile=request('/user');login=profile['login']
 try:
  existing=request('/repos/'+login+'/bus47c-game')
  print('REPOSITORY_ALREADY_EXISTS '+existing['html_url']);raise SystemExit(3)
 except urllib.error.HTTPError as e:
  if e.code!=404:raise
 repo=request('/user/repos',{'name':'bus47c-game','description':'Bus 47C - low-poly first-person horror game','private':True,'auto_init':False})
 print('CREATED '+repo['html_url'])
except urllib.error.HTTPError as e:print('GITHUB_HTTP_STATUS',e.code);raise SystemExit(4)
