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
$ duffle uninstall|status|upgrade -c kubeconfig my_release
```

## BUILD


```bash
# Build a new version of the bundle
$ duffle build .
```

Due to this bug https://github.com/deis/duffle/issues/337, after building the bundle we can not just `inspect it` but there is a workaround that finds the correct bundle and moves it to the working directory.

```bash
# Export the generated bundle
$ cp ~/.duffle/bundles/$(grep wordpress -A1 ~/.duffle/repositories.json | tail -1 | awk -F': ' '{print $2}' | awk -F'\"' '{print $2}') ./bundle.cnab
```
