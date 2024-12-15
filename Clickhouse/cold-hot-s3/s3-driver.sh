wget https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-aws-mountpoint-s3-csi-driver-1.11.0/aws-mountpoint-s3-csi-driver-1.11.0.tgz

tar zxvf aws-mountpoint-s3-csi-driver-1.11.0.tgz

cd aws-mountpoint-s3-csi-driver

helm install as-s3-driver . --values values.yaml -n kube-system --debug