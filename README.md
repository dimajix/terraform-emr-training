# 1. Preparations

## Prepare SSH key

First of all you need to create an SSH key pair for securely accessing the cluster.

    ssh-keygen -t rsa -C "EMR Access Key" -f deployer-key
    puttygen deployer-key -o deployer-key.ppk

## Create AWS Route53 Zone

The Terraform scripts will regsiter all master nodes in the public DNS via
Route53. Therefore you need to provide a AWS Route53 zone in advance which can
be used for creating appropriate DNS records.

## Create AWS Configuration

You need to copy the `aws-config.tf.template` file to `aws-config.tf` and modify 
it so that it contains your AWS credentials and the desired AWS region and 
availability zone. You can also specify the file name of the SSH key.

## Modify General Configuration

Now that you have everything together, you also might want to adjust some
settings in `main.tf`. Per default four EMR clusters will be created, each
having two nodes (one master and one worker). At least you need to specify
the Route53 zone to use.

The following properties can be set in the `emr` section in `main.tf`:

* `proxy_domain` Specify set the Route53 zone name for registering the
  web-interfaces to the public DNS. This setting has to match the corresponding
  domain name and will be used for setting up the reverse proxy
* `proxy_user` Configure the user name used for basic http authentication. This
provides a very basic level of security for the clusters.
* `proxy_password` Configure the corresponding password for http basic auth to
the web interfaces.
* `names` Configures the names of the clusters. For each name a separate EMR
  cluster will be created.
* `release` Specfify the desired EMR release
* `application` Specify the EMR components to be installed.
* `master_type` Set the desired EC2 instance type for the master
* `worker_type` Set the desired EC2 instance type for the worker

In addition the following properties can be set in the `route53` section
in `main.tf`:

* `zone_name` Again this needs to contain the Route53 zone name where all
DNS entries are created. The scripts will NOT create this zone, it has be
be provided by you in advance.

You also might want to change the network configuration, but if you change the
subnets, you also should adjust `foxy-proxy.xml` with the corresponding settings.


# 2. Starting and stopping the Clusters

## Start Cluster

    terraform init
    terraform apply

## Destroy Cluster

    terraform destroy

Note that you probably need to destroy the security groups manually in the
web-interface, since cycling dependencies are not handled correctly in
Terraform

## Manual Cleanup

Sometimes it might be neccessary to clean up some resources manually, where
not AWS web frontend is available:

    aws iam remove-role-from-instance-profile --role-name training_ec2_role --instance-profile-name training_ec2_profile
    aws iam delete-instance-profile --instance-profile-name training_ec2_profile


# 3. Connect to Cluster

You can then connect to the cluster via SSH

    ssh -i deployer-key hadoop@<cluster_name>.<route_53_zone_name>

where `cluster_name` is one of the `names` configured in `main.tf` and
`route_53_zone_name` is the Route53 zone where all computers will be registered.

## Web Interface

As part of the deployment a reverse proxy will be setup such that you can
access most services via your web-browser. You can find an entry page at

    http://<cluster_name>.<route_53_zone_name>

where `cluster_name` is one of the `names` configured in `main.tf` and
`route_53_zone_name` is the Route53 zone where all computers will be registered.

## Web Tunnel Connection

You can create a proxy tunnel using SSH dynamic port forwarding, which again can
be easily used with FoxyProxy plugin.

    ssh -i deployer-key -ND 8157 hadoop@<cluster_name>.<route_53_zone_name>

The tunneled URLs for the relevant services in EMR are as follows:

    YARN - http://master:8088
    HDFS - http://master:50070
    Hue - http://master:8888
    Zeppelin - http://master:8890
    Spark History - http://master:18080
    Jupyter Notebook - http://master:8899

