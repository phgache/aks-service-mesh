label_values(istio_requests_total, source_workload_namespace) => SourceWorkloadNamespace
label_values(istio_requests_total, destination_workload_namespace) => DestinationWorkloadNamespace

label_values(istio_requests_total{source_workload_namespace=~"^$SourceWorkloadNamespace$"}, source_workload) => SourceWorkload
label_values(istio_requests_total{destination_workload_namespace=~"^$DestinationWorkloadNamespace$"}, destination_workload) => DestinationWorkload

## Ingress Success Rate (non-4|5xx responses)

### Nginx

sum(rate(nginx_ingress_controller_requests{controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress",status!~"[4-5].*"}[2m])) by (ingress) 
/ sum(rate(nginx_ingress_controller_requests{controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (ingress)

### Istio

sum(rate(istio_requests_total{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace",response_code!~"[4-5].*"}[2m]))
/ sum(rate(istio_requests_total{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m]))

## Ingress Percentile Response Times and Transfer Rates

### Nginx

histogram_quantile(0.50, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!="",controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (le, ingress))

histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!="",controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (le, ingress))

histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!="",controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (le, ingress))

sum(irate(nginx_ingress_controller_request_size_sum{ingress!="",controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (ingress)

sum(irate(nginx_ingress_controller_response_size_sum{ingress!="",controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (ingress)

### Istio

histogram_quantile(0.50, sum(rate(istio_request_duration_seconds_bucket{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])) by (le,source_app, destination_app))

histogram_quantile(0.90, sum(rate(istio_request_duration_seconds_bucket{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])) by (le,source_app, destination_app))

histogram_quantile(0.99, sum(rate(istio_request_duration_seconds_bucket{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])) by (le,source_app, destination_app))

sum(irate(istio_request_bytes_sum{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])) by (source_app, destination_app)

sum(irate(istio_request_bytes_sum{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])) by (source_app, destination_app)


## Ingress Request Volume

### Nginx

round(sum(irate(nginx_ingress_controller_requests{controller_pod=~"$Controller",controller_class=~"$ControllerClass",ingress=~"$Ingress"}[2m])) by (ingress), 0.001)

### Istio

round(sum(irate(istio_requests_total{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m])), 0.001)

## Network I/O pressure

### Nginx

sum (irate (nginx_ingress_controller_request_size_sum{controller_pod=~"$Controller",controller_class=~"$ControllerClass"}[2m]))

- sum (irate (nginx_ingress_controller_response_size_sum{controller_pod=~"$Controller",controller_class=~"$ControllerClass"}[2m]))

### Istio

sum (irate (istio_request_bytes_sum{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m]))

- sum (irate (istio_response_bytes_sum{destination_workload=~"$DestinationWorkload",destination_workload_namespace=~"$DestinationWorkloadNamespace",source_workload=~"$SourceWorkload",source_workload_namespace=~"$SourceWorkloadNamespace"}[2m]))