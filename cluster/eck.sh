
#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Elastic Cloud on Kubernetes  --'
echo '----------------------------------'

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: elasticsearch-es-elastic-user
  namespace: $ELASTIC_NAMESPACE
  labels:
    common.k8s.elastic.co/type: elasticsearch
    elasticsearch.k8s.elastic.co/cluster-name: elasticsearch
type: Opaque
data:
  elastic: $ELASTIC_PASSPHRASE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: $ELASTIC_NAMESPACE
spec:
  version: 7.6.0
  http:
    tls: 
      selfSignedCertificate:
        disabled: true
  nodeSets:
  - name: default
    count: 2
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 64Gi
        storageClassName: premium-lrs-sc
    config:
      node.store.allow_mmap: false
    podTemplate:
      metadata:
        annotations:
          traffic.sidecar.istio.io/excludeOutboundPorts: "9300" 
          traffic.sidecar.istio.io/excludeInboundPorts: "9300"
      spec:
        containers:
        - name: elasticsearch
          env:
          - name: ES_JAVA_OPTS
            value: -Xms1g -Xmx1g
          resources:
            requests:
              memory: 2Gi
              cpu: 0.5
            limits:
              memory: 2Gi
              cpu: 1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana  
  namespace: $ELASTIC_NAMESPACE
spec:
  version: 7.6.0
  count: 1
  elasticsearchRef:
    name: elasticsearch
  http:
    tls: 
      selfSignedCertificate:
        disabled: true
  podTemplate:
    metadata:
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true" 
    spec:
      containers:
      - name: kibana
        resources:
          requests:
            memory: 512Mi
            cpu: 0.5
          limits:
            memory: 1Gi
            cpu: 1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apm.k8s.elastic.co/v1
kind: ApmServer
metadata:
  name: apmserver
  namespace: $ELASTIC_NAMESPACE
spec:
  version: 7.6.0
  count: 1
  config:
    logging:
      level: debug
  elasticsearchRef:
    name: elasticsearch
  http:
    tls: 
      selfSignedCertificate:
        disabled: true
  podTemplate:
    metadata:
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
    spec:
      containers:
      - name: apm-server
        resources:
          requests:
            memory: 512Mi
            cpu: 0.5
          limits:
            memory: 1Gi
            cpu: 1
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: $ELASTIC_NAMESPACE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: fluentd
  namespace: $ELASTIC_NAMESPACE
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
EOF

cat <<EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: $ELASTIC_NAMESPACE
EOF

cat <<EOF | kubectl apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluentd-config
  namespace: $ELASTIC_NAMESPACE
data:
  100.system.conf: |-
    <system>
      root_dir /tmp/fluentd-buffers/
    </system>
  200.containers.input.conf: |-
    <match fluent.**>
      @type null
    </match>
    # Capture logs from container's stdout/stderr -> Docker -> .log in JSON format
    <source>
      @id containers-stdout-stderr
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/containers-stdout-stderr.pos
      tag raw.kubernetes.*
      format json
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    # Capture logs from Knative containers' /var/log
    <source>
      @id containers-var-log
      @type tail
      # **/*/**/* allows path expansion to go through one symlink (the one created by the init container)
      path /var/lib/kubelet/pods/*/volumes/kubernetes.io~empty-dir/knative-internal/**/*/**/*
      path_key stream
      pos_file /var/log/containers-var-log.pos
      tag raw.kubernetes.*
      message_key log
      read_from_head true
      <parse>
        @type multi_format
        <pattern>
          format json
          time_key fluentd-time # fluentd-time is reserved for structured logs
          time_format %Y-%m-%dT%H:%M:%S.%NZ
        </pattern>
        <pattern>
          format none
          message_key log
        </pattern>
      </parse>
    </source>
    # Combine multi line logs which form an exception stack trace into a single log entry
    <match raw.kubernetes.**>
      @id raw.kubernetes
      @type detect_exceptions
      remove_tag_prefix raw
      message log
      stream stream
      multiline_flush_interval 5
      max_bytes 500000
      max_lines 1000
    </match>
    # Make stream path correct from the container's point of view
    <filter kubernetes.var.lib.kubelet.pods.*.volumes.kubernetes.io~empty-dir.knative-internal.*.**>
      @type record_transformer
      enable_ruby true
      <record>
        stream /var/log/${record["stream"].scan(/\/knative-internal\/[^\/]+\/(.*)/).last.last}
      </record>
    </filter>
    # Add Kubernetes metadata to logs from /var/log/containers
    <filter kubernetes.var.log.containers.**>
      @type kubernetes_metadata
    </filter>
    # Add Kubernetes metadata to logs from /var/lib/kubelet/pods/*/volumes/kubernetes.io~empty-dir/knative-internal/**/*/**/*
    <filter kubernetes.var.lib.kubelet.pods.**>
      @type kubernetes_metadata
      tag_to_kubernetes_name_regexp (?<docker_id>[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})\.volumes.kubernetes\.io~empty-dir\.knative-internal\.(?<namespace>[^_]+)_(?<pod_name>[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*)_(?<container_name>user-container)\..*?$
    </filter>
  300.forward.input.conf: |-
    # Takes the messages sent over TCP, e.g. request logs from Istio
    <source>
      @type forward
      port 24224
    </source>
  900.output.conf: |-
    # Send to Elastic Search
    <match **>
      @id elasticsearch
      @type elasticsearch
      @log_level info
      host "#{ENV['FLUENT_ELASTICSEARCH_HOST']}"
      port "#{ENV['FLUENT_ELASTICSEARCH_PORT']}"
      scheme "#{ENV['FLUENT_ELASTICSEARCH_SCHEME'] || 'https'}"
      user "#{ENV['FLUENT_ELASTICSEARCH_USER']}"
      password "#{ENV['FLUENT_ELASTICSEARCH_PASSWORD']}"
      logstash_format true
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: $ELASTIC_NAMESPACE
  labels:
    app: fluentd
    version: v2.0.4
spec:
  selector:
    matchLabels:
      app: fluentd
      version: v2.0.4
  template:
    metadata:
      labels:
        app: fluentd
        version: v2.0.4
      # This annotation ensures that fluentd does not get evicted if the node
      # supports critical pod annotation based priority scheme.
      # Note that this does not guarantee admission on the nodes (#40573).
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: k8s.gcr.io/fluentd-elasticsearch:v2.0.4
        env:
        - name: FLUENTD_ARGS
          value: --no-supervisor -q
        - name:  FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch-es-http"
        - name:  FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
        - name: FLUENT_ELASTICSEARCH_USER
          value: "elastic"
        - name: FLUENT_ELASTICSEARCH_PASSWORD
          value: $PASSWORD
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
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
        - name: config-volume
          mountPath: /etc/fluent/config.d
      terminationGracePeriodSeconds: 30
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
      - name: config-volume
        configMap:
          name: fluentd-config
EOF



kubectl get secret/apmserver-apm-token -n elastic-system -o go-template='{{index .data "secret-token" | base64decode}}'

