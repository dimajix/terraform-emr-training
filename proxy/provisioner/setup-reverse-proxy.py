#!/usr/bin/python3

import pystache
import os
import os.path
import sys
import argparse
import htpasswd
import time
from OpenSSL import crypto, SSL

curdir = os.path.abspath(os.path.dirname(__file__))

HTTPD_CONF_DIR = '/etc/apache2'
CERT_DIR = '/etc/apache2/ssl'


def render_template(template, target, env):
    index_template = open(os.path.join(curdir, template)).read()
    index_html = pystache.render(index_template, env)
    print(f"Generating {template} -> {target}")
    dirname = os.path.dirname(target)
    if not os.path.exists(dirname):
        os.makedirs(dirname, 755)
    with open(target, 'wt') as f:
        f.write(index_html)
    os.chmod(target, 644)


def render_httpd_template(template, env):
    aliasName = env['aliasHostName']
    target = aliasName + template.replace(".template", "").replace("apache-proxy", "")
    filename = os.path.join(HTTPD_CONF_DIR, "sites-available", target)
    linkname = os.path.join(HTTPD_CONF_DIR, "sites-enabled", target)
    render_template(template, filename, env)
    os.symlink(filename, linkname)


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


def link_certificate(hostname, keyfile, certfile):
    print(f"Linking {certfile} -> {os.path.join(CERT_DIR, hostname + '.cert')}")
    if not os.path.exists(CERT_DIR):
        os.makedirs(CERT_DIR, 755)
    os.symlink(certfile, os.path.join(CERT_DIR, hostname + ".cert"))
    os.symlink(keyfile, os.path.join(CERT_DIR, hostname + ".key"))


def setup_single_cluster(env):
    aliasName = env['aliasHostName']

    htpasswd = f"/var/www/html/{aliasName}/htpasswd"
    setup_htpasswd(htpasswd, env)
    env["htpasswd"] = htpasswd

    render_template('index.html.template', f'/var/www/html/{aliasName}/index.html', env)
    render_httpd_template('apache-proxy-top.conf.template', env)
    render_httpd_template('apache-proxy-nn.conf.template', env)
    render_httpd_template('apache-proxy-ap.conf.template', env)
    render_httpd_template('apache-proxy-rm.conf.template', env)
    render_httpd_template('apache-proxy-hue.conf.template', env)
    render_httpd_template('apache-proxy-hbase.conf.template', env)
    render_httpd_template('apache-proxy-zeppelin.conf.template', env)
    render_httpd_template('apache-proxy-jupyter.conf.template', env)

    keyfile = env['ssl_keyfile']
    certfile = env['ssl_certfile']
    link_certificate(aliasName, keyfile, certfile)
    link_certificate('nn.' + aliasName, keyfile, certfile)
    link_certificate('ap.' + aliasName, keyfile, certfile)
    link_certificate('rm.' + aliasName, keyfile, certfile)
    link_certificate('hue.' + aliasName, keyfile, certfile)
    link_certificate('hbase.' + aliasName, keyfile, certfile)
    link_certificate('zeppelin.' + aliasName, keyfile, certfile)
    link_certificate('jupyter.' + aliasName, keyfile, certfile)

    #create_certificate(hostname)
    #create_certificate('nn.' + hostname)
    #create_certificate('ap.' + hostname)
    #create_certificate('rm.' + hostname)
    #create_certificate('hue.' + hostname)
    #create_certificate('hbase.' + hostname)
    #create_certificate('zeppelin.' + hostname)
    #create_certificate('jupyter.' + hostname)


def setup_htpasswd(filename, env):
    with open(filename, 'wt') as userdb:
        pass
    os.chmod(filename, 644)
    with htpasswd.Basic(filename) as userdb:
        userdb.add(env['username'], env['password'])


def parse_args(raw_args):
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--domain', dest='domain', help='Domain for registering proxy host', default='training.dimajix-aws.net')
    parser.add_argument('-u', '--username', dest='username', help='Username for authentication', default='dimajix-training')
    parser.add_argument('-p', '--password', dest='password', help='Password for authentication', default='dmx2018')
    parser.add_argument('-N', '--names', dest='names', help='Nice names to create proxies for', default='kku')
    parser.add_argument('-H', '--hosts', dest='hosts', help='Target machines to proxy', default='')
    parser.add_argument('-C', '--ssl-certfile', dest='certfile', help='SSL certificate file', default='/etc/httpd/ssl/dummy.cert')
    parser.add_argument('-K', '--ssl-keyfile', dest='keyfile', help='SSL private key file', default='/etc/httpd/ssl/dummy.key')

    return parser.parse_args(args=raw_args)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])

    hostnames = args.hosts.split(",")
    alias_names = args.names.split(",")

    for hostname, alias in zip(hostnames, alias_names):
        alias_domain = alias + "." + args.domain
        env = {
            'target_master': hostname,
            'aliasHostName': alias_domain,
            'username': args.username,
            'password': args.password,
            'ssl_certfile': args.certfile,
            'ssl_keyfile': args.keyfile
        }

        setup_single_cluster(env)


# TODO
#  * htpasswd
#  * file permissions
