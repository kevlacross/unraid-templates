#!/usr/bin/env python3
import json,re,subprocess,tempfile,xml.etree.ElementTree as E
from pathlib import Path
root=Path(__file__).resolve().parent
source=json.loads((root/'upstream/release-compose.json').read_text())
assert dict(line.split('=',1) for line in (root/'config/nocturne-gateway.env.in').read_text().splitlines())==source['services']['gateway']['environment']
assert 'POSTGRES_USER=nocturne\n' in (root/'config/nocturne-postgres-server.env.in').read_text()
assert 'PGPASSWORD=' in (root/'config/00-init.sh').read_text()
for f in (root.parent/'templates').glob('0*-nocturne-*.xml'):
 c=E.parse(f).getroot();assert c.get('version')=='2';assert c.findtext('Privileged')=='false'
 assert '--env-file=/mnt/user/appdata/nocturne/' in c.findtext('ExtraParams')
 assert 'docker.sock' not in f.read_text()
 assert c.findtext('Network')=='nocturne'
 assert ':latest' not in c.findtext('Repository')
 if c.findtext('Name')!='nocturne-gateway':assert not any(x.get('Type')=='Port' for x in c.findall('Config'))
with tempfile.TemporaryDirectory() as td:
 output=Path(td)/'private'
 cmd=['bash',str(root/'prepare.sh'),'nocturne.example.com','/mnt/user/appdata/nocturne',str(output)]
 subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL)
 for f in output.rglob('*'):
  if f.is_file():assert not re.search(r'@[A-Z_]+@',f.read_text()),f
 assert (output/'config/00-init.sh').stat().st_mode & 0o004
 secret_file=output/'config/nocturne-api.env';before=secret_file.read_bytes()
 assert subprocess.run(cmd,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode!=0
 assert secret_file.read_bytes()==before
 for domain in ['localhost','192.0.2.1','foo..example.com','x;id.example.com','https://example.com']:
  assert subprocess.run(['bash',str(root/'prepare.sh'),domain,'/tmp/nocturne',str(Path(td)/'bad')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode!=0
 subprocess.run(['bash','-n',str(output/'start.sh')],check=True)
print('PASS: four XML templates, release routing parity, private port layout, secret rendering, bootstrap permissions, overwrite protection, input validation and shell syntax')

for f in (root.parent/"templates").glob("*.xml"):
 c=E.parse(f).getroot()
 assert c.findtext("TemplateURL")=="https://raw.githubusercontent.com/kevlacross/unraid-templates/main/templates/"+f.name
 assert c.findtext("Support")=="https://github.com/kevlacross/unraid-templates/issues"
 assert not re.search(r"@[A-Z_]+@",f.read_text())
 assert c.findtext("Requires")
print("PASS: canonical public template URLs, maintainer support links, prerequisites and usable CA defaults")
