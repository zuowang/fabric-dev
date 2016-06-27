#Use pprof debug docker daemon

- [pprof debug entrypoint](#pprof-debug-entrypoint)
- [Start docker daemon in debug mode](#start-docker-daemon-in-debug-mode)
- [Run socat to make docker sock available via tcp port](#run-socat-to-make-docker-sock-available-via-tcp-port)
- [Access debug url entrypoint](#access-debug-url-entrypoint)
	- [show global vars](#show-global-vars)
	- [get command line](#get-command-line)
	- [run pprof on your client:](#run-pprof-on-your-client)
	- [get symbol](#get-symbol)
	- [other](#other)


# pprof debug entrypoint
> source file: [docker\api\server\profiler.go](https://github.com/docker/docker/blob/master/api/server/profiler.go)

```go
func profilerSetup(mainRouter *mux.Router, path string) {
    var r = mainRouter.PathPrefix(path).Subrouter()
    r.HandleFunc("/vars", expVars)
    r.HandleFunc("/pprof/", pprof.Index)
    r.HandleFunc("/pprof/cmdline", pprof.Cmdline)
    r.HandleFunc("/pprof/profile", pprof.Profile)
    r.HandleFunc("/pprof/symbol", pprof.Symbol)
    r.HandleFunc("/pprof/block", pprof.Handler("block").ServeHTTP)
    r.HandleFunc("/pprof/heap", pprof.Handler("heap").ServeHTTP)
    r.HandleFunc("/pprof/goroutine", pprof.Handler("goroutine").ServeHTTP)
    r.HandleFunc("/pprof/threadcreate", pprof.Handler("threadcreate").ServeHTTP)
}
```

# Start docker daemon in debug mode
> add -D to command line

```shell
$ /usr/bin/docker daemon -D -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```

# Run socat to make docker sock available via tcp port
> note the IP to listen at

```shell
$ socat -d -d TCP-LISTEN:8080,fork,bind=192.168.1.137 UNIX:/var/run/docker.sock
  2016/01/23 12:59:43 socat[3113] N listening on AF=2 192.168.1.137:8080
```

# Access debug url entrypoint


## show global vars

```js
$ curl -s http://192.168.1.137:8080/debug/vars | jq .
  {
    "cmdline": [
      "/usr/bin/docker",
      "daemon",
      "-D",
      "-H",
      "tcp://0.0.0.0:2375",
      "-H",
      "unix:///var/run/docker.sock",
      "-api-enable-cors",
      "--storage-driver=aufs",
      "--insecure-registry",
      "registry.hyper.sh:5000",
      "--insecure-registry",
      "192.168.1.137:5000"
    ],
    "memstats": {
      "Alloc": 7140904,
      "TotalAlloc": 20379824,
      "Sys": 14559480,
      "Lookups": 3090,
      "Mallocs": 313164,
      "Frees": 199260,
      "HeapAlloc": 7140904,
  ...
```

## get command line

```shell
$ curl -s http://192.168.1.137:8080/debug/pprof/cmdline
  /usr/bin/docker daemon -D -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock -api-enable-cors --storage-driver=aufs --insecure-registry registry.hyper.sh:5000 --insecure-registry 192.168.1.137:5000
```

## run pprof on your client:

```shell
$ go tool pprof http://192.168.1.137:8080/debug/pprof/profile
  Fetching profile from http://192.168.1.137:8080/debug/pprof/profile
  Please wait... (30s)
  Saved profile in /home/xjimmy/pprof/pprof.192.168.1.137:8080.samples.cpu.001.pb.gz
  Entering interactive mode (type "help" for commands)
  (pprof) web     
  (pprof) web ploop
  (pprof)
```

## get symbol

```shell
$ curl -s http://192.168.1.137:8080/debug/pprof/symbol
  num_symbols: 1
```

## other

```
$ culr -s http://192.168.1.137:8080/debug/pprof/block
$ curl -s http://192.168.1.137:8080/debug/pprof/heap
$ curl -s http://192.168.1.137:8080/debug/pprof/goroutine
$ curl -s http://192.168.1.137:8080/debug/pprof/threadcreate
```
