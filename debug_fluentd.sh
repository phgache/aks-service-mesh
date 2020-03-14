kubectl get nodes --show-labels

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: fluentd-debug
  labels:
    app: fluentd-debug
spec:
  nodeSelector:
    kubernetes.io/hostname: aks-linuxpool-35064155-vmss000002
  containers:
    - name: fluentd
      image: k8s.gcr.io/fluentd-elasticsearch:v2.0.4
      volumeMounts:
      - name: varlogcontainers
        mountPath: /var/log/containers
        readOnly: true
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
      - name: varlibkubeletpods
        mountPath: /var/lib/kubelet/pods
        readOnly: true
      - name: libsystemddir
        mountPath: /host/lib
        readOnly: true
  volumes:
  - name: varlogcontainers
    hostPath:
      path: /var/log/containers
  - # It is needed because files under /var/log/containers link to /var/log/pods
    name: varlogpods
    hostPath:
      path: /var/log/pods
  - # It is needed because files under /var/log/pods link to /var/lib/docker/containers
    name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  - # It is needed because user-container's /var/log is located in /var/lib/kubelet/pods/*/volumes/
    name: varlibkubeletpods
    hostPath:
      path: /var/lib/kubelet/pods
  - # It is needed to copy systemd library to decompress journals
    name: libsystemddir
    hostPath:
      path: /usr/lib64
EOF

kubectl wait --for=condition=Ready pod -l app=fluentd-debug

kubectl exec -it fluentd-debug -- /bin/bash

kubectl delete pod fluentd-debug