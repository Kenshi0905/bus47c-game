$ErrorActionPreference='Stop'
$env:GIT_TERMINAL_PROMPT='0'
$credentialLines="protocol=https`nhost=github.com`n`n" | git credential fill
$credentialMap=@{}
foreach($entry in $credentialLines){$pair=$entry.Split('=',2);if($pair.Count -eq 2){$credentialMap[$pair[0]]=$pair[1]}}
if(-not $credentialMap['password']){throw 'No stored GitHub credential'}
$headers=@{Authorization=('Bearer '+$credentialMap['password']);Accept='application/vnd.github+json';'User-Agent'='Bus47C-setup'}
$profile=Invoke-RestMethod https://api.github.com/user -Headers $headers
$url='https://api.github.com/repos/'+$profile.login+'/bus47c-game'
try{$existing=Invoke-RestMethod $url -Headers $headers; Write-Output ('EXISTS '+$existing.html_url);exit 3}catch{if([int]$_.Exception.Response.StatusCode -ne 404){throw}}
$body=@{name='bus47c-game';description='Bus 47C - low-poly first-person horror game';private=$true;auto_init=$false}|ConvertTo-Json
$repo=Invoke-RestMethod https://api.github.com/user/repos -Method Post -Headers $headers -ContentType 'application/json' -Body $body
Write-Output ('CREATED '+$repo.html_url)
