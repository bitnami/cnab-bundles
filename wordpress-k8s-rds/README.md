# WordPress on Kubernetes with RDS database

[WordPress](https://wordpress.org/) is one of the most versatile open source content management systems on the market. A publishing platform for building blogs and websites.

[Amazon Relational Database Service](https://aws.amazon.com/rds) (Amazon RDS) is a web service that makes it easier to set up, operate, and scale a relational database in the cloud

## TL;DR;

```bash
$ duffle install my-wordpress -c wordpress-creds -f ./bundle.cnab
```

## Introduction

This [CNAB bundle](https://cnab.io) bootstraps a MariaDB RDS database as well as a [WordPress](https://github.com/bitnami/bitnami-docker-wordpress) deployment on a [Kubernetes](http://kubernetes.io) cluster.

Under the hood, this package provisions the RDS database using a Cloud Formation template and deploys WordPress by relying on the Bitnami [WordPress Helm chart](https://github.com/helm/charts/tree/master/stable/wordpress).

See it in action in the following video:

[![Bundle installation video](https://img.youtube.com/vi/RJZhJr4q5Sw/0.jpg )](https://www.youtube.com/watch?v=RJZhJr4q5Sw)

## Prerequisites

* AWS account with permissions to provision RDS databases and deploy Cloud Formation Stacks.
* Kubernetes 1.4+
* [Tiller](https://docs.helm.sh/install/#installing-tiller) installed in the Kubernetes cluster


## Installing the CNAB Bundle

> **Important:** The default configuration is not recommended for production purposes, see the [Securing Installation](#securing-the-installation) section for more information.

In order to manage the bundle, we are going to use a command line tool called [Duffle](https://duffle.sh), please ensure that you [have installed](https://github.com/deislabs/duffle/releases) its latest version before continue.

### Clone this repository

Clone this repository to download the bundle and the verification key to your filesystem:

```
$ git clone https://github.com/bitnami/cnab-bundles
$ cd ./cnab-bundles/wordpress-k8s-rds
```

### Import Signing Key

CNAB bundles, by default, are signed by their provider and importing a verification key is required to verify the integrity and source of the package.

> **Tip**: Alternatively you can append the `--insecure` flag to every duffle command


```bash
# verification-public.key can be found in the git repo, download it and then run:
$ duffle key add verification-public.key
```

### Define Credentials


Some credentials from your environment need to be supplied to the bundle. Specifically, AWS credentials are required to manage Cloud Formation and RDS databases and a Kubernetes `kube/config` file is required to deploy and manage applications in Kubernetes.  

First, generate a credentials file:


```bash
$ duffle creds generate wordpress-creds -f ./bundle.cnab
```

This will create a file in ~/.duffle/credentials/wordpress-creds.yaml showing the credentials needed with empty values.

You can either fill the values in directly, or edit them by typing:

```bash
$ duffle creds edit wordpress-creds
```

### Parameters

The following table lists the configurable parameters of the WordPress CNAB bundle and their default values.

|            Parameter             |                Description                 |                         Default                         |
|----------------------------------|--------------------------------------------|---------------------------------------------------------|
| `database-password`           | Database password, 8 alphanumeric chars minimum | `random alphanumeric string`|
| `aws-default-region`          | AWS region where the RDS database will be provisioned | `us-west-2` |
|`app-domain`|The domain used to expose the WordPress instance, if set it will configure a k8s ingress resource|`nil`|
|`app-tls`|TLS configuration for the `app-domain` ingress including the required `cert-manager` annotations|`false`|


### Usage Examples

Installation with default settings, random database password and application expose via a LoadBalancer IP address

```bash
$ duffle install my-release -c wordpress-creds -f ./bundle.cnab
```

Installation with specific database password and application URL + TLS configured

```bash
$ duffle install my-release -c wordpress-creds --set app-domain=wordpress.mydomain.com --set app-tls=true -f ./bundle.cnab
```

You can also update, uninstall or get the status of a release

```
$ duffle uninstall|status|upgrade my-release -c wordpress-creds
```

### Bitnami Kubernetes Production Runtime integration

This bundle is compatible with [Bitnami Kubernetes Production Runtime](https://github.com/bitnami/kube-prod-runtime) (BKPR) which provides logging, monitoring, certificate and public DNS management.  

Once installed, it will take advantage of the monitoring and logging capabilities automatically but in order to let BKPR manage the DNS and TLS certificates you need to install this bundle setting the `app-domain` and `app-tls` parameters.

```bash
$ duffle install my-release -c wordpress-creds --set app-domain=wordpress.kubeprod-domain.com --set app-tls=true -f ./bundle.cnab
```

## Securing The Installation

### Limit network access to the RDS database

By default, the RDS database is deployed alongside a security group that allows inbound access to the port 3306 from any IP address.

We recommend that this configuration is changed to only allow inbound traffic from your Kubernetes cluster security group (if applicable) or limit the cidr inbound rule to known IP addresses (i.e your nodes IP addresses).

### SSL communication between WordPress and RDS database

By default, the communication between WordPress and the database is not encrypted. You can enable TLS encryption by using one of the available [Wordpress plugins](https://wordpress.org/plugins/secure-db-connection). On the AWS side, just follow the instructions that can be found [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html#MariaDB.Concepts.SSLSupport).

## Troubleshooting

### Issue installing the bundle in GKE or EKS

Both Amazon and Google Kubernetes services (EKS and GKE) rely on local tools (`aws-iam-authenticator` and `gcloud` respectively) to perform authentication. The bundle invocation image does not include those tools and providing the `.kube/config` file is not always enough, that's why you might get errors like this one during the validation step.

```
err=fork/exec gcloud: no such file or directory output= stderr=
```

If you are running into this issue, there is a way to workaround it by refreshing the access token stored in `.kube/config` before performing any action with `duffle`. In order to refresh the token, you just need to run any `kubectl` command, i.e `kubectl get pods`. Once done, the operation on the bundle should work as expected.

## Development


```bash
# Build a new version of the bundle
$ duffle build .
```


```bash
# Export the generated bundle
duffle show wordpress-k8s-rds:devel --raw > ./bundle.cnab
```
