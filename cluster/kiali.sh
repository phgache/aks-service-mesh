
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
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: $KIALI_NAMESPACE
  annotations:
    ansible.operator-sdk/verbosity: "3"
spec:
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
    image_version: $KIALI_VERSION
    service_type: ClusterIP
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