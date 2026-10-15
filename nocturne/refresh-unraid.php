<?php
$_SERVER['DOCUMENT_ROOT']='/usr/local/emhttp';
$_SERVER['REQUEST_URI']='';
require_once '/usr/local/emhttp/plugins/dynamix.docker.manager/include/DockerClient.php';
$update=new DockerUpdate();
$docker=new DockerClient();
foreach($docker->getDockerContainers() as $ct) {
 if(!in_array($ct['Name'],['nocturne-api','nocturne-web','nocturne-postgres-server','nocturne-gateway']))continue;
 $update->reloadUpdateStatus($ct['Image']);
 echo $ct['Name'].': '.var_export($update->getUpdateStatus($ct['Image']),true).PHP_EOL;
}
$templates=new DockerTemplates();
$info=DockerUtil::loadJSON($dockerManPaths['webui-info']);
foreach($docker->getDockerContainers() as $ct) {
 if(!in_array($ct['Name'],['nocturne-api','nocturne-web','nocturne-postgres-server','nocturne-gateway']))continue;
 $name=$ct['Name'];
 $info[$name]['updated']=var_export($update->getUpdateStatus($ct['Image']),true);
 $info[$name]['template']=$templates->getUserTemplate($name);
 $info[$name]['icon']=$templates->getIcon($ct['Image'],$name,'https://raw.githubusercontent.com/nightscout/nocturne/v0.2.7/src/Web/packages/app/static/favicon.png');
}
DockerUtil::saveJSON($dockerManPaths['webui-info'],$info);
