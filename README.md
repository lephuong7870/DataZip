# Steps For Setting the SuperSet and Clichouse in Minikube

# Perquisites

```txt
1) Any Cloud Account
2) Terraform
3) Helm
4) Superset
5) Clickhouse
```

# Install Kubernetes Using Script

### `Step1: On Master Node Only`

```sh
## Install Docker
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installDocker.sh -P /tmp
sudo chmod 755 /tmp/installDocker.sh
sudo bash /tmp/installDocker.sh
sudo systemctl restart docker.service

## Install CRI-Docker
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installCRIDockerd.sh -P /tmp
sudo chmod 755 /tmp/installCRIDockerd.sh
sudo bash /tmp/installCRIDockerd.sh
sudo systemctl restart cri-docker.service

## Install kubeadm,kubelet,kubectl
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installK8S.sh -P /tmp
sudo chmod 755 /tmp/installK8S.sh
sudo bash /tmp/installK8S.sh

# Validate 

   docker -v
   cri-dockerd --version
   kubeadm version -o short
   kubelet --version
   kubectl version --client

## Initialize kubernetes Master Node
 
   sudo kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock --ignore-preflight-errors=all

   sudo mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config

   ## install networking driver -- Weave/flannel/canal/calico etc... 

   ## below installs calico networking driver 
    
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml

   # Validate:  kubectl get nodes
```

### `Step2: On All Worker Nodes`

```sh
## Install Docker
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installDocker.sh -P /tmp
sudo chmod 755 /tmp/installDocker.sh
sudo bash /tmp/installDocker.sh
sudo systemctl restart docker.service

## Install CRI-Docker
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installCRIDockerd.sh -P /tmp
sudo chmod 755 /tmp/installCRIDockerd.sh
sudo bash /tmp/installCRIDockerd.sh
sudo systemctl restart cri-docker.service

## Install kubeadm,kubelet,kubectl
sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/scripts/installK8S.sh -P /tmp
sudo chmod 755 /tmp/installK8S.sh
sudo bash /tmp/installK8S.sh


# Validate 

   docker -v
   cri-dockerd --version
   kubeadm version -o short
   kubelet --version
   kubectl version --client

# Enable and configure bridge networking and iptables filtering for Docker or other containerization tools. 

sudo modprobe bridge
cat /proc/sys/net/bridge/bridge-nf-call-iptables
sudo modprobe br_netfilter
cat /proc/sys/net/bridge/bridge-nf-call-iptables
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
   
## Run Below on Master Node to get join token 

kubeadm token create --print-join-command 

    copy the kubeadm join token from master &
           ensure to add --cri-socket unix:///var/run/cri-dockerd.sock as below &
           ensure to add sudo 
           then run on worker nodes

    Ex: sudo kubeadm join 10.128.15.231:6443  --token mks3y2.v03tyyru0gy12mbt \
           --discovery-token-ca-cert-hash sha256:3de23d42c7002be0893339fbe558ee75e14399e11f22e3f0b34351077b7c4b56 --cri-socket unix:///var/run/cri-dockerd.sock
```

# By default core DNS will be 2 replicas

```sh
kubectl get pods -n kube-system

kubectl edit deploy coredns -n kube-system

By changing the replicas the coredns pods to your current nodes

example 
 replicas: 2 to 
 replicas: 3

```

# Install Terraform

### `For Linux (Ubuntu/Debian-based distributions):`
```sh
sudo apt update
sudo apt install -y gnupg software-properties-common
wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo apt-add-repository "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install terraform
terraform --version
```

# Install helm

### `For Linux (Ubuntu/Debian-based distributions):`

```sh
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

# Deploy Superset & ClickHouse

### `1.Clone the Github Repo`

```sh
git clone https://github.com/shashank3656/DataZip.git
unzip Datazip  # For installing Unzip sudo apt install unzip
cd Datazip/Terraform
```

### `2. Geneate the Password for ClickHouse using Double hax`

```sh
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha1sum | tr -d '-' | xxd -r -p | sha1sum | tr -d '-'
```

```txt
replace the Output in the configmap.yaml in the below file <password_double_sha1_hex>Replace</password_double_sha1_hex>

users.xml: |
    <?xml version="1.0"?>
    <clickhouse>
        <profiles>
            <!-- Default profile with memory and load balancing configurations -->
            <default>
                <max_memory_usage>10000000</max_memory_usage>  <!-- Set max memory usage to 10 GB -->
                <load_balancing>random</load_balancing>
            </default>
            <!-- Readonly profile with readonly flag set -->
            <readonly>
                <readonly>1</readonly>
            </readonly>
        </profiles>

        <users> 
          <!-- Default user configuration -->
          <default>
            <password_double_sha1_hex>7dc366355ed7a983876a29d69a9586d5c2bd98b4</password_double_sha1_hex>
            <networks>
              <ip>::/0</ip>  <!-- Allow connections from any IP address -->
            </networks>
            <profile>default</profile>
            <quota>default</quota>
          </default>
        </users>

        <quotas>
            <default>
                <interval>
                    <duration>3600</duration>  <!-- 1 hour interval -->
                    <queries>1000</queries>  <!-- Allow 1000 queries per interval -->
                    <errors>20</errors>  <!-- Allow 10 errors per interval -->
                    <result_rows>10000000</result_rows>  <!-- Limit to 10 million result rows -->
                    <read_rows>100000000</read_rows>  <!-- Limit to 100 million read rows -->
                    <execution_time>3600</execution_time>  <!-- Max execution time of 3600 seconds (1 hour) -->
                </interval>
            </default>
        </quotas>
    </clickhouse>
```


### `3.Deploy the SuperSet & ClickHouse using Terraform Script`

### `main.tf`
```tf
# Provider Name Kubernetes
provider "kubernetes" {
    config_path = var.kubeconfig_path
}

# Provider Name Helm
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Namespace for ClickHouse
resource "kubernetes_namespace" "clickhouse" {
    metadata {
        name = var.namespace_clickhouse
    }
}

# Namespace for Superset
resource "kubernetes_namespace" "superset" {
    metadata {
        name = var.namespace_superset
    }
}

# ClickHouse PV File 
resource "kubernetes_manifest" "clickhouse-pv" {
    depends_on = [ kubernetes_namespace.clickhouse ]
    manifest = yamldecode(file(var.pv_file_path))
}

# ClickHouse PVC File 
resource "kubernetes_manifest" "clickhouse-pvc" {
    depends_on = [ kubernetes_manifest.clickhouse-pv ]
    manifest = yamldecode(file(var.pvc_file_path))
}

# ClickHouse ConfigMAP File 
resource "kubernetes_manifest" "clickhouse-configmap" {
    depends_on = [ kubernetes_manifest.clickhouse-pvc ]
    manifest = yamldecode(file(var.config_file_path))
}

# ClickHouse Deployment File 
resource "kubernetes_manifest" "clickhouse-deployment" {
    depends_on = [ kubernetes_manifest.clickhouse-configmap ]
    manifest = yamldecode(file(var.deploy_file_path))
}

# ClickHouse Service File 
resource "kubernetes_manifest" "clickhouse-service" {
    depends_on = [ kubernetes_manifest.clickhouse-deployment ]
    manifest = yamldecode(file(var.service_file_path))
}

# SuperSet Using Helm
# Helm release for Superset with custom values.yaml
resource "helm_release" "superset" {
    depends_on = [ var.namespace_superset ]
    name       = var.superset_name
    namespace  = var.namespace_superset
    chart      = var.chart_path  # Path to local Helm chart
    
    values = [file(var.values_file)]  # Use your custom values.yaml file
    # Optional: Wait for the release to be fully deployed before finishing
    wait = true
    
    # Optional: Timeout for Helm install
    timeout = 600  # in seconds
}
```

### `Variables.tf`
```tf
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
}

variable "namespace_clickhouse" {

}

variable "namespace_superset" {

}

variable "deploy_file_path" {

}

variable "service_file_path" {
  
}

variable "pv_file_path" {
  
}

variable "pvc_file_path" {
  
}

variable "config_file_path" {
  
}

variable "superset_name" {
  
}

variable "chart_path" {
  
}

variable "values_file" {
  
}
```

### `terraform.tfvars`
```tf
kubeconfig_path = "~/.kube/config"

# clichouse
namespace_clickhouse = "clickhouse"
deploy_file_path = "~/clickhouse/deployment.yaml"
service_file_path = "~/clickhouse/service.yaml"
pv_file_path = "~/clickhouse/pv.yaml"
pvc_file_path = "~/clickhouse/pvc.yaml"
config_file_path = "~/clickhouse/configmap.yaml"

# superset
namespace_superset = "superset"
superset_name = "superset"
chart_path = "./superset-chart" 
values_file = "./values.yaml"
```

# Steps for Hot-Cold Strategy

### `1. Steps for setting the s3 driver`

```sh
wget https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-aws-mountpoint-s3-csi-driver-1.11.0/aws-mountpoint-s3-csi-driver-1.11.0.tgz
tar zxvf aws-mountpoint-s3-csi-driver-1.11.0.tgz
cd aws-mountpoint-s3-csi-driver
helm install as-s3-driver . --values values.yaml -n kube-system --debug
```

### `2. Driver-Level Credentials with K8s Secrets`

```sh
kubectl create secret generic aws-secret \
    --namespace kube-system \
    --from-literal "key_id=${AWS_ACCESS_KEY_ID}" \
    --from-literal "access_key=${AWS_SECRET_ACCESS_KEY}"
```

### `3. Driver-Level Credentials with Node IAM Profiles`

```text
To use an IAM [instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html), attach the policy to the instance profile IAM role and turn on access to [instance metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) for the instance(s) on which the driver will run.
```

### `4. Create a Bucket`

```sh
aws s3api create-bucket --bucket my-app-bucket-2024 --region us-east-1
```

### `5. Add the Bucket Policy`

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MountpointFullBucketAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::s3-bucket-clickhouse-1"
        },
        {
            "Sid": "MountpointFullObjectAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::s3-bucket-clickhouse-1/*"
        }
    ]
}
```

### `6. Create PV & PVC for Mounting to s3`

```yaml
## PV & PVC Monuting to S3
apiVersion: v1
kind: PersistentVolume
metadata:
  name: clickhouse-s3-pv
spec:
  capacity:
    storage: 10Gi  # The storage size for the S3-backed volume
  accessModes:
    - ReadWriteMany  # Allows multiple pods to read/write the volume
  storageClassName: ""  # Required for static provisioning
  claimRef:  # Ensures the PVC can only claim this PV
    namespace: clickhouse  # The namespace where the PVC is defined
    name: clickhouse-s3-pvc  # PVC name
  mountOptions:
    - allow-delete
    - region=us-east-1  # S3 region, replace with your region
  csi:
    driver: s3.csi.aws.com  # S3 CSI Driver
    volumeHandle: s3-csi-driver-volume  # Unique volume handle
    volumeAttributes:
      bucketName: s3-bucket-clickhouse-1  # Replace with your S3 bucket name

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: clickhouse-s3-pvc
  namespace: clickhouse  # The namespace where this PVC will be used
spec:
  accessModes:
    - ReadWriteMany  # Allows multiple pods to access the volume
  storageClassName: ""  # This is for static provisioning
  resources:
    requests:
      storage: 10Gi  # Requested storage size
  volumeName: clickhouse-s3-pv  # The PV that this PVC will claim
```

```sh
kubectl apply -f pv-s3.yaml
```

### `7. Setup the Config-Map with S3 Hot & Cold Strategy`

```yaml
## ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: clickhouse-userconfigmap
  namespace: clickhouse
data:
  storage.xml: |
    <clickhouse>
      <listen_host>0.0.0.0</listen_host>
      <path>/data/clickhouse/</path>  <!-- Hot data path on local storage -->

      <disks>
        <!-- Default local disk for hot storage -->
        <default>
          <path>/data/clickhouse/</path> <!-- Hot data stored locally -->
        </default>

        <!-- S3 disk for cold storage -->
        <s3>
          <type>s3</type>
          <endpoint>https://s3-bucket-clickhouse-1.s3.us-east-1.amazonaws.com/data/</endpoint> <!-- Replace with your S3 bucket endpoint -->
          #<access_key_id>AKIA5FTZCHRINFSSSCXM</access_key_id> <!-- Your AWS Access Key -->
          #<secret_access_key>loHd78xdP7nKyZ92y8qLuNQLRx1HbAYwq2FPrAbg</secret_access_key> <!-- Your AWS Secret Key -->
          <region>us-east-1</region> <!-- S3 region -->
          <use_environment_credentials>false</use_environment_credentials>
          <metadata_path>/var/lib/clickhouse/disks/s3/</metadata_path> <!-- Path for storing metadata locally -->
        </s3>

        <!-- S3 cache for cold data -->
        <s3_cache>
          <type>cache</type>
          <disk>s3</disk>
          <path>/var/lib/clickhouse/disks/s3_cache/</path> <!-- Cache path -->
          <max_size>10Gi</max_size> <!-- Maximum cache size -->
        </s3_cache>
      </disks>

      <policies>
        <!-- Cold storage policy using S3 -->
        <s3_main>
          <volumes>
            <main>
              <disk>s3</disk> <!-- Cold storage will use S3 -->
            </main>
          </volumes>
        </s3_main>

        <!-- Tiered storage policy: Hot data on local disk, cold data on S3 -->
        <s3_tiered>
          <volumes>
            <hot>
              <disk>default</disk> <!-- Hot data will be stored on local disk -->
            </hot>
            <main>
              <disk>s3</disk> <!-- Cold data will be stored on S3 -->
            </main>
          </volumes>
          <move_factor>0.2</move_factor> <!-- Move data to cold storage when disk usage exceeds 20% -->
        </s3_tiered>
      </policies>
    </clickhouse>

  access_management.xml: |
    <clickhouse>
      <users>
        <default>
          <access_management>1</access_management>
          <named_collection_control>1</named_collection_control>
          <show_named_collections>1</show_named_collections>
          <show_named_collections_secrets>1</show_named_collections_secrets>
          <double_sha1_passwords>1</double_sha1_passwords>
        </default>
      </users>
    </clickhouse>

  users.xml: |
    <?xml version="1.0"?>
    <clickhouse>
      <profiles>
        <!-- Default profile with memory and load balancing configurations -->
        <default>
          <max_memory_usage>10000000</max_memory_usage> <!-- Set max memory usage to 10 GB -->
          <load_balancing>random</load_balancing>
        </default>
        <!-- Readonly profile with readonly flag set -->
        <readonly>
          <readonly>1</readonly>
        </readonly>
      </profiles>

      <users>
        <!-- Default user configuration -->
        <default>
          <password_double_sha1_hex>7dc366355ed7a983876a29d69a9586d5c2bd98b4</password_double_sha1_hex>
          <networks>
            <ip>::/0</ip> <!-- Allow connections from any IP address -->
          </networks>
          <profile>default</profile>
          <quota>default</quota>
        </default>
      </users>

      <quotas>
        <default>
          <interval>
            <duration>3600</duration> <!-- 1 hour interval -->
            <queries>1000</queries> <!-- Allow 1000 queries per interval -->
            <errors>20</errors> <!-- Allow 20 errors per interval -->
            <result_rows>10000000</result_rows> <!-- Limit to 10 million result rows -->
            <read_rows>100000000</read_rows> <!-- Limit to 100 million read rows -->
            <execution_time>3600</execution_time> <!-- Max execution time of 3600 seconds (1 hour) -->
          </interval>
        </default>
      </quotas>
    </clickhouse>
```


```sh
kubectl apply -f config-s3.yaml
```


### `8. Deploy the deployment`

```yaml
## Deployment

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: clickhouse
  namespace: clickhouse
spec:
  replicas: 1
  selector:
    matchLabels:
      app: clickhouse
  template:
    metadata:
      labels:
        app: clickhouse
    spec:
      volumes:
        - name: clickhouse-userconfigmap
          configMap:
            name: clickhouse-userconfigmap
        - name: clickhouse-storage
          persistentVolumeClaim:
            claimName: clickhouse
        - name: clickhouse-s3
          persistentVolumeClaim:
            claimName: clickhouse-s3-pvc
      containers:
        - name: clickhouse
          image: clickhouse/clickhouse-server:24.8.8.17
          ports:
            - containerPort: 8123
            - containerPort: 9000
          resources:
            limits:
              cpu: 600m
              memory: 2Gi
            requests:
              cpu: 300m
              memory: 1Gi
          volumeMounts:
            - name: clickhouse-userconfigmap
              mountPath: /etc/clickhouse-server/users.xml
              subPath: users.xml
            - name: clickhouse-userconfigmap
              mountPath: /etc/clickhouse-server/users.d/default.xml
              subPath: access_management.xml
            - name: clickhouse-userconfigmap
              mountPath: /etc/clickhouse-server/config.d/default_config.xml
              subPath: storage.xml
            - name: clickhouse-storage
              mountPath: /data
            - name: clickhouse-s3
              mountPath: /data
```

```sh
kubectl apply -f deployment-s3.yaml
```


### `9. SQL Queries`

```sql
-- Normal Local

CREATE DATABASE dz_test;

USE dz_test;

CREATE TABLE dz_test
(
    B Int64,          -- A 64-bit integer column
    T String,         -- A string (text) column
    D Date            -- A date column
) 
ENGINE = MergeTree          -- Using the MergeTree engine for table storage
PARTITION BY D              -- Partitioning the data by the 'D' (Date) column
ORDER BY B                  -- Ordering data by the 'B' column for efficient query execution


insert into dz_test select number, number, '2023-01-01' from numbers(1e4);
select * from dz_test


-- Hot & Cold Strategy 

insert into dz_test select number, number, '2023-01-01' from numbers(1e9);

CREATE DATABASE dz_test;

USE dz_test;

CREATE TABLE dz_test
(
    col1 UInt32,
    col2 UInt32,
    col3 Date
)
ENGINE = S3('https://s3.amazonaws.com/your-bucket-name/path/to/folder/', 'access-key-id', 'secret-access-key')
FORMAT CSV;

INSERT INTO dz_test
SELECT number, number, '2023-01-01' 
FROM numbers(1e9);

```


# Reference

```txt
- [Superset Helm Chart](https://github.com/apache/superset/releases/tag/superset-helm-chart-0.13.4)
- [Click House Installation](https://clickhouse.com/docs/en/install)
- [AWS S3 Driver Helm Chart](https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-aws-mountpoint-s3-csi-driver-1.11.0/aws-mountpoint-s3-csi-driver-1.11.0.tgz)
- [AWS Intergating with Clickhouse](https://clickhouse.com/docs/en/integrations/s3)
```