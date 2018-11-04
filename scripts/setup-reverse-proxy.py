import urllib2
import socket
import json
import pystache
import os
import os.path
import sys
import argparse
import htpasswd
import time
from OpenSSL import crypto, SSL

curdir = os.path.abspath(os.path.dirname(__file__))

HTTPD_CONF_DIR = '/etc/httpd/conf.d'
CERT_DIR = '/etc/httpd/ssl'

def wait_hadoop():
    hostname = socket.getfqdn()
    response = None

    while not response:
        try:
            response = urllib2.urlopen("http://" + hostname + ":8088/ws/v1/cluster/nodes")
        except:
            time.sleep(1)


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


def render_template(template, target, env):
    index_template = open(os.path.join(curdir,template)).read()
    index_html = pystache.render(index_template, env)
    with open(target,'wt') as f:
        f.write(index_html)


def render_httpd_template(template, env):
    target = template.replace(".template", "")
    render_template(template, os.path.join(HTTPD_CONF_DIR, target), env)


def create_certificate(hostname):
    # create a key pair
    k = crypto.PKey()
    k.generate_key(crypto.TYPE_RSA, 1024)

    serial = int(time.time())

    # create a self-signed cert
    cert = crypto.X509()
    subject = cert.get_subject()
    subject.C = "DE"
    subject.ST = "Hessen"
    subject.L = "Frankfurt"
    subject.O = "dimajix"
    subject.OU = "dimajix Training"
    subject.CN = hostname
    cert.set_serial_number(serial)
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(10*24*60*60)
    cert.set_issuer(subject)
    cert.set_pubkey(k)
    cert.sign(k, 'sha1')

    if not os.path.exists(CERT_DIR):
        os.makedirs(CERT_DIR)

    certfile = os.path.join(CERT_DIR, hostname + '.cert')
    if not os.path.exists(certfile):
        with open(certfile, 'wt') as f:
            f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, k))
            f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, cert))


def setup_apache(args):
    env = create_env(args)
    render_template('index.html.template', '/var/www/html/index.html', env)
    render_httpd_template('apache-proxy.conf.template', env)
    render_httpd_template('apache-proxy-nn.conf.template', env)
    render_httpd_template('apache-proxy-ap.conf.template', env)
    render_httpd_template('apache-proxy-rm.conf.template', env)
    render_httpd_template('apache-proxy-hue.conf.template', env)
    render_httpd_template('apache-proxy-hbase.conf.template', env)
    render_httpd_template('apache-proxy-zeppelin.conf.template', env)
    render_httpd_template('apache-proxy-jupyter.conf.template', env)

    hostname = env['aliasHostName']
    create_certificate(hostname)
    create_certificate('nn.' + hostname)
    create_certificate('ap.' + hostname)
    create_certificate('rm.' + hostname)
    create_certificate('hue.' + hostname)
    create_certificate('hbase.' + hostname)
    create_certificate('zeppelin.' + hostname)
    create_certificate('jupyter.' + hostname)

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
    wait_hadoop()
    setup_apache(args)

