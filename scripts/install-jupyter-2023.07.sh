#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"

ANACONDA_PREFIX=/opt/anaconda3
ANACONDA_VERSION=2023.07-2
ANACONDA_INSTALLER=Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh
ANACONDA_USER=hadoop
ANACONDA_USER_HOME=$(eval echo ~${ANACONDA_USER})

SPARK_HOME=/usr/lib/spark
SPARK_MASTER=yarn

is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_anaconda() {
    # Download Anaconda3 if it is not already present
    if [ ! -f ${ANACONDA_INSTALLER} ];
    then
        sudo wget https://repo.continuum.io/archive/${ANACONDA_INSTALLER}
        sudo chmod a+rx ${ANACONDA_INSTALLER}
    fi

    # Start automatic installation into /opt/anaconda3. The parameters
    #  -f force the installation, even if the directory already exists
    #  -b silently accepts the license
    #  -p specifies the installation location
    sudo sh ${ANACONDA_INSTALLER} -f -b -p ${ANACONDA_PREFIX}
    sudo rm -f ${ANACONDA_INSTALLER}
    
    sudo yum -y install cmake3 libzstd python3-boto3 python2-boto3
    sudo ln -sf /usr/bin/cmake3 /usr/bin/cmake

    # Update some components, otherwise PyArrow cannot be installed
    sudo ${ANACONDA_PREFIX}/bin/conda update --yes --freeze anaconda lz4-c openssl
    # Install as much as possible via Anaconda
    sudo ${ANACONDA_PREFIX}/bin/conda install --yes --freeze pyarrow=11.0.0 s3fs=2023.4.0 cartopy=0.21.1 geos=3.8.0 proj=8.2.1 pyproj=3.4.1 pyshp=2.1.3 shapely=2.0.1
    sudo ${ANACONDA_PREFIX}/bin/pip install contextily==1.4.0 geopandas==0.14.0
}


configure_jupyter_notebook() {
    sudo -u ${ANACONDA_USER} mkdir -p ${ANACONDA_USER_HOME}/.jupyter
    sudo -u ${ANACONDA_USER} tee ${ANACONDA_USER_HOME}/.jupyter/jupyter_notebook_config.py >/dev/null <<EOL
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8899

c.NotebookApp.token = ''
c.NotebookApp.password = ''
EOL
}


install_pyspark_kernel() {
    sudo mkdir -p ${ANACONDA_PREFIX}/share/jupyter/kernels/PySpark3
    sudo tee ${ANACONDA_PREFIX}/share/jupyter/kernels/PySpark3/kernel.json >/dev/null <<EOL
{
 "display_name": "PySpark",
 "language": "python",
 "argv": [
  "${ANACONDA_PREFIX}/bin/python3",
  "-m", "ipykernel",
  "-f", "{connection_file}"
 ],
 "env": {
  "TZ": "UTC",
  "SPARK_MAJOR_VERSION": "${SPARK_MAJOR_VERSION}",
  "SPARK_HOME": "${SPARK_HOME}",
  "PYTHONPATH": "${SPARK_HOME}/python/:${SPARK_HOME}/python/lib/py4j-src.zip",
  "PYTHONSTARTUP": "${SPARK_HOME}/python/pyspark/shell.py",
  "PYSPARK_PYTHON": "${ANACONDA_PREFIX}/bin/python3",
  "PYSPARK_SUBMIT_ARGS": "--master ${SPARK_MASTER} --driver-memory=2G pyspark-shell"
 }
}
EOL
}


install_startup() {
    sudo tee /etc/systemd/system/jupyter-notebook.service > /dev/null <<EOL
[Unit]
Description=Jupyter Notebook

[Service]
Environment=JAVA_HOME=/etc/alternatives/jre
Type=exec
ExecStart=/usr/bin/su -s /bin/bash hadoop -c "cd ${ANACONDA_USER_HOME} && ${ANACONDA_PREFIX}/bin/jupyter-notebook --NotebookApp.ip=0.0.0.0 --NotebookApp.port=8899"
Restart=always
RestartSec=5
PIDFile=/var/run/jupyter-notebook.pid


[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl start jupyter-notebook
}


install_anaconda

if is_master;
then
    configure_jupyter_notebook
    install_pyspark_kernel
    install_startup
fi

