import urllib2
import socket
import json
import pystache
import os.path
import sys
import argparse
import htpasswd

curdir = os.path.abspath(os.path.dirname(__file__))


def create_env(args):
    hostname = socket.getfqdn()
    response = urllib2.urlopen("http://" + hostname + ":8088/ws/v1/cluster/nodes")
    env = json.loads(response.read())
    env['master'] = {'masterHostName':hostname}
    env['aliasHostName'] = args.domain
    env['username'] = args.username
    env['password'] = args.password
    env['htpasswd'] = os.path.join(curdir, 'htpasswd')
    return env


def setup_apache(args):
    env = create_env(args)
    index_template = open(os.path.join(curdir,"index.html.template")).read()
    index_html = pystache.render(index_template, env)
    with open('/var/www/html/index.html','wt') as f:
        f.write(index_html)

    apache_template = open(os.path.join(curdir,"apache-proxy.conf.template")).read()
    apache_conf = pystache.render(apache_template, env)
    with open('/etc/httpd/conf.d/proxy.conf','wt') as f:
        f.write(apache_conf)

    with open(env["htpasswd"],'wt') as userdb:
        pass
    with htpasswd.Basic(env["htpasswd"]) as userdb:
        userdb.add(env['username'], env['password'])


def parse_args(raw_args):
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--domain', dest='domain', help='Domain for registering proxy host', default='training.dimajix-aws.net')
    parser.add_argument('-u', '--username', dest='username', help='Username for authentication', default='dimajix-training')
    parser.add_argument('-p', '--password', dest='password', help='Password for authentication', default='dmx2018')

    return parser.parse_args(args=raw_args)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    setup_apache(args)

