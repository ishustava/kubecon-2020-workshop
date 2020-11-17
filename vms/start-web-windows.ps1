$env:NAME='web'
$env:LISTEN_ADDR='0.0.0.0:8080'
$env:UPSTREAM_URIS='http://127.0.0.1:9090'
./bin/web/web.exe
