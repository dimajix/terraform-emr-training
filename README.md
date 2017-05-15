# Preparations

## Prepare SSH key

First of all you need to create an SSH key pair for securely accessing the cluster.

    ssh-keygen -b 2048 -t rsa -C "EMR Access Key" -f deployer-key

## Create AWS Configuration

You need to copy the `aws-config.tf.template` file to `aws-config.tf` and modify 
it so that it contains your AWS credentials and the desired AWS region and 
availability zone. You can also specify the file name of the SSH key.

## Modify General Configuration

Now that you have everything together, you also might want to adjust some
settings in `main.tf`. Per default four EMR clusters will be created, each
having two nodes (one master and one worker). 

You also might want to change the network configuration, but if you change the
subnets, you also should adjust `foxy-proxy.xml` with the corresponding settings.


# Running the Clusters

## Start Cluster

    terraform get
    terraform apply

## Destroy Cluster

    terraform destroy

## Connect to Cluster

    ssh -i deployer_key hadoop@ec2-1-2-3-4.eu-central-1.compute.amazonaws.com

## Web Connection

You can create a proxy tunnel using SSH dynamic port forwarding, which again can
be easily used with FoxyProxy plugin.

    ssh -i deployer-key.pem -ND 8157 hadoop@ec2-1-2-3-4.eu-central-1.compute.amazonaws.com

The URLs for the relevant services in EMR are as follows:

    YARN - http://master:8088
    HDFS - http://master:50070
    Hue - http://master:8888
    Zeppelin - http://master:8890
    Spark History - http://master:18080
    Jupyter Notebook - http://master:8888

