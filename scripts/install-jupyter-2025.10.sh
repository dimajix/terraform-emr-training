#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"

MINIFORGE_PREFIX=/opt/miniforge
MINIFORGE_VERSION=25.9.1-0
MINIFORGE_INSTALLER=Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh
MINIFORGE_USER=hadoop
MINIFORGE_USER_HOME=$(eval echo ~${MINIFORGE_USER})

SPARK_HOME=/usr/lib/spark
SPARK_MASTER=yarn

is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_miniforge() {
    # Download Miniforge if it is not already present
    if [ ! -f ${MINIFORGE_INSTALLER} ];
    then
        sudo wget https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/${MINIFORGE_INSTALLER}
        sudo chmod a+rx ${MINIFORGE_INSTALLER}
    fi

    # Start automatic installation into /opt/anaconda3. The parameters
    #  -f force the installation, even if the directory already exists
    #  -b silently accepts the license
    #  -p specifies the installation location
    sudo sh ${MINIFORGE_INSTALLER} -f -b -p ${MINIFORGE_PREFIX}
    sudo rm -f ${MINIFORGE_INSTALLER}
    
    sudo yum -y install cmake3 libzstd python3-boto3 python2-boto3
    sudo ln -sf /usr/bin/cmake3 /usr/bin/cmake

    # Update some components, otherwise PyArrow cannot be installed
    sudo ${MINIFORGE_PREFIX}/bin/conda update --yes --freeze conda lz4-c openssl
    # Install as much as possible via Miniforge
    sudo ${MINIFORGE_PREFIX}/bin/conda install --yes --freeze pyarrow=22.0.0 s3fs=2023.4.0 cartopy=0.25.0 geos=3.14.1 proj=9.7.0 pyproj=3.7.2 pyshp=3.0.2 shapely=2.1.2 jupyter=1.1.1
    sudo ${MINIFORGE_PREFIX}/bin/pip install contextily==1.4.0 geopandas==0.14.0
}


configure_jupyter_notebook() {
    sudo -u ${MINIFORGE_USER} mkdir -p ${MINIFORGE_USER_HOME}/.jupyter
    sudo -u ${MINIFORGE_USER} tee ${MINIFORGE_USER_HOME}/.jupyter/jupyter_notebook_config.py >/dev/null <<EOL
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8899

c.NotebookApp.token = ''
c.NotebookApp.password = ''
EOL
}


install_pyspark_kernel() {
    sudo mkdir -p ${MINIFORGE_PREFIX}/share/jupyter/kernels/PySpark3
    sudo tee ${MINIFORGE_PREFIX}/share/jupyter/kernels/PySpark3/kernel.json >/dev/null <<EOL
{
 "display_name": "PySpark",
 "language": "python",
 "argv": [
  "${MINIFORGE_PREFIX}/bin/python3",
  "-m", "ipykernel",
  "-f", "{connection_file}"
 ],
 "env": {
  "TZ": "UTC",
  "SPARK_MAJOR_VERSION": "${SPARK_MAJOR_VERSION}",
  "SPARK_HOME": "${SPARK_HOME}",
  "PYTHONPATH": "${SPARK_HOME}/python/:${SPARK_HOME}/python/lib/py4j-src.zip",
  "PYTHONSTARTUP": "${SPARK_HOME}/python/pyspark/shell.py",
  "PYSPARK_PYTHON": "${MINIFORGE_PREFIX}/bin/python3",
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
ExecStart=/usr/bin/su -s /bin/bash hadoop -c "cd ${MINIFORGE_USER_HOME} && ${MINIFORGE_PREFIX}/bin/jupyter-notebook --NotebookApp.ip=0.0.0.0 --NotebookApp.port=8899"
Restart=always
RestartSec=5
PIDFile=/var/run/jupyter-notebook.pid


[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl start jupyter-notebook
}


install_miniforge

if is_master;
then
    configure_jupyter_notebook
    install_pyspark_kernel
    install_startup
fi

