## USAGE

Import the verification key

NOTE: Alternatively you can attach the `--insecure` flag to every single command

```bash
# Import key for signature checking
$ duffle key add verification-public.key
```


Generate and configure a credential set 

```bash
$ duffle creds generate wordpress-creds -f ./bundle.cnab
```

Install Wordpress in k8s

```
$ duffle install -c wordpress-creds my_release -f ./bundle.cnab
```

You can also update, uninstall or get the status of a release

```
$ duffle uninstall|status|upgrade -c wordpress-creds my_release
```

## BUILD


```bash
# Build a new version of the bundle
$ duffle build .
```


```bash
# Export the generated bundle
duffle inspect wordpress-k8s-rds:0.1.0 --raw > ./bundle.cnab
```
