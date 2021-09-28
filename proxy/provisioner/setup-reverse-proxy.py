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


def ensure_directory(dirname):
    if not os.path.exists(dirname):
        os.makedirs(dirname, 755)


def ensure_parentdir(filename):
    dirname = os.path.dirname(filename)
    if not os.path.exists(dirname):
        os.makedirs(dirname, 755)


def render_template(template, target, env):
    index_template = open(os.path.join(curdir, template)).read()
    index_html = pystache.render(index_template, env)
    print(f"Generating {template} -> {target}")
    ensure_parentdir(target)
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

    ensure_directory(CERT_DIR)

    certfile = os.path.join(CERT_DIR, hostname + '.cert')
    if not os.path.exists(certfile):
        with open(certfile, 'wt') as f:
            f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, k))
            f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, cert))


def link_certificate(hostname, keyfile, certfile):
    print(f"Linking {certfile} -> {os.path.join(CERT_DIR, hostname + '.cert')}")
    ensure_directory(CERT_DIR)
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

    certdir = env['ssl_certdir']
    keyfile = os.path.join(certdir, "root-privkey.pem")
    certfile = os.path.join(certdir, "root-cert.pem")
    link_certificate(aliasName, keyfile, certfile)

    keyfile = os.path.join(certdir, env['name'] + "-privkey.pem")
    certfile = os.path.join(certdir, env['name'] + "-cert.pem")
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
    ensure_parentdir(filename)
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
    parser.add_argument('--pubic-masters', dest='public_masters', help='Target machines to proxy', default='')
    parser.add_argument('--private-masters', dest='private_masters', help='Target machines to proxy', default='')
    parser.add_argument('-C', '--ssl-certdir', dest='certdir', help='SSL certificate directory', default='')

    return parser.parse_args(args=raw_args)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])

    public_masters = args.public_masters.split(",")
    private_masters = args.private_masters.split(",")
    alias_names = args.names.split(",")

    for public_master, private_master, alias in zip(public_masters, private_masters, alias_names):
        alias_domain = alias + "." + args.domain
        env = {
            'public_master': public_master,
            'private_master': private_master,
            'name': alias,
            'aliasHostName': alias_domain,
            'username': args.username,
            'password': args.password,
            'ssl_certdir': args.certdir
        }

        setup_single_cluster(env)

