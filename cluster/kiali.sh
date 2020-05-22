
#!/bin/bash
set -e

echo '----------------------------------'
echo '-- Kiali                        --'
echo '----------------------------------'

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $KIALI_NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: istio-pilot
  namespace: $ISTIO_NAMESPACE
spec:
  host: istio-pilot.istio-system.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 10000
        maxRequestsPerConnection: 10000
    portLevelSettings:
    - port:
        number: 15010
      tls:
        mode: ISTIO_MUTUAL
    - port:
        number: 15011
      tls:
        mode: ISTIO_MUTUAL
    - port:
        number: 15014
      tls:
        mode: ISTIO_MUTUAL
    - port:
        number: 8080
      tls:
        mode: DISABLE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: $KIALI_NAMESPACE
  annotations:
    ansible.operator-sdk/verbosity: "3"
spec:
  istio_component_namespaces:
  - prometheus: $PROMETHEUS_NAMESPACE
  - grafana: $GRAFANA_NAMESPACE
  - kiali: $KIALI_NAMESPACE
  istio_namespace: $ISTIO_NAMESPACE
  identity:
    cert_file: ""
  api:
    namespaces:
      exclude:
      - istio-operator
      - observability
      - $CERT_MANAGER_NAMESPACE
      - default
  deployment:
    verbose_mode: "3"
    namespace: $KIALI_NAMESPACE
    image_version: "v1.15.0"
    service_type: "ClusterIP"
  extensions:
    threescale:
      enabled: true
    iter8:
      enabled: false
  server:
    web_root: "/"
  external_services:
    grafana:
      auth:
        ca_file: ""
        insecure_skip_verify: false
        password: $PASSWORD
        type: basic
        use_kiali_token: false
        username: "grafana"
      dashboards:
      - name: "Cluster Monitoring"
        variables:
          namespace: "var-Namespace"
      - name: "Vote App Metrics"
      enabled: true
      in_cluster_url: http://grafana.${GRAFANA_NAMESPACE}.svc:80
      url: https://grafana.${DOMAIN_NAME}
    prometheus:
      auth:
        ca_file: ""
        insecure_skip_verify: false
        password: ""
        type: none
        use_kiali_token: false
        username: ""
      custom_metrics_url: http://prometheus-server.${PROMETHEUS_NAMESPACE}.svc:80
      url: https://prometheus.${DOMAIN_NAME}
    tracing:
      auth:
        ca_file: ""
        insecure_skip_verify: false
        password: ""
        type: none
        use_kiali_token: false
        username: ""
      enabled: true
      in_cluster_url: http://jaeger-query.${JAEGER_NAMESPACE}.svc:16686
      url: https://jaeger.${DOMAIN_NAME}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: meshpolicies-cr
rules:
- apiGroups:
  - "authentication.istio.io"
  resources:
  - meshpolicies
  verbs:
  - get
  - list
  - watch
EOF

cat <<EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: meshpolicies-crb
roleRef:
  kind: ClusterRole
  name: meshpolicies-cr
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: kiali-service-account
  namespace: $KIALI_NAMESPACE
EOF