package kube

import "encoding/yaml"

configMap: prometheus: {
	"alert.rules": yaml.Marshal(alert_rules)
	alert_rules = {
		groups: [{
			name: "rules.yaml"
			rules: [{
				alert: "InstanceDown"
				expr:  "up == 0"
				for:   "30s"
				labels: severity: "page"
				annotations: {
					description: "{{$labels.app}} of job {{ $labels.job }} has been down for more than 30 seconds."
					summary:     "Instance {{$labels.app}} down"
				}
			}, {
				alert: "InsufficientPeers"
				expr:  "count(up{job=\"etcd\"} == 0) > (count(up{job=\"etcd\"}) / 2 - 1)"
				for:   "3m"
				labels: severity: "page"
				annotations: {
					description: "If one more etcd peer goes down the cluster will be unavailable"
					summary:     "etcd cluster small"
				}
			}, {
				alert: "EtcdNoMaster"
				expr:  "sum(etcd_server_has_leader{app=\"etcd\"}) == 0"
				for:   "1s"
				labels: severity:     "page"
				annotations: summary: "No ETCD master elected."
			}, {
				alert: "PodRestart"
				expr:  "(max_over_time(pod_container_status_restarts_total[5m]) - min_over_time(pod_container_status_restarts_total[5m])) > 2"
				for:   "1m"
				labels: severity: "page"
				annotations: {
					description: "{{$labels.app}} {{ $labels.container }} resturted {{ $value }} times in 5m."
					summary:     "Pod for {{$labels.container}} restarts too often"
				}
			}]
		}]
	}
	"prometheus.yml": yaml.Marshal(prometheus_yml)
	prometheus_yml = {
		global: scrape_interval: "15s"
		rule_files: ["/etc/prometheus/alert.rules"]
		alerting: alertmanagers: [{
			scheme: "http"
			static_configs: [{
				targets: ["alertmanager:9093"]
			}]
		}]
		scrape_configs: [{
			job_name: "kubernetes-apiservers"
			kubernetes_sd_configs: [{
				role: "endpoints"
			}]
			// Default to scraping over https. If required, just disable this or change to
			// `http`.
			scheme: "https"
			// This TLS & bearer token file config is used to connect to the actual scrape
			// endpoints for cluster components. This is separate to discovery auth
			// configuration because discovery & scraping are two separate concerns in
			// Prometheus. The discovery auth config is automatic if Prometheus runs inside
			// the cluster. Otherwise, more config options have to be provided within the
			// <kubernetes_sd_config>.
			tls_config: ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
			// If your node certificates are self-signed or use a different CA to the
			// master CA, then disable certificate verification below. Note that
			// certificate verification is an integral part of a secure infrastructure
			// so this should only be disabled in a controlled environment. You can
			// disable certificate verification by uncommenting the line below.
			//
			// insecure_skip_verify: true
			bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
			// Keep only the default/kubernetes service endpoints for the https port. This
			// will add targets for each API server which Kubernetes adds an endpoint to
			// the default/kubernetes service.
			relabel_configs: [{
				source_labels: ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
				action: "keep"
				regex:  "default;kubernetes;https"
			}]
		}, {
			// Scrape config for nodes (kubelet).
			//
			// Rather than connecting directly to the node, the scrape is proxied though the
			// Kubernetes apiserver.  This means it will work if Prometheus is running out of
			// cluster, or can't connect to nodes for some other reason (e.g. because of
			// firewalling).
			job_name: "kubernetes-nodes"
			// Default to scraping over https. If required, just disable this or change to
			// `http`.
			scheme: "https"
			// This TLS & bearer token file config is used to connect to the actual scrape
			// endpoints for cluster components. This is separate to discovery auth
			// configuration because discovery & scraping are two separate concerns in
			// Prometheus. The discovery auth config is automatic if Prometheus runs inside
			// the cluster. Otherwise, more config options have to be provided within the
			// <kubernetes_sd_config>.
			tls_config: ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
			bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
			kubernetes_sd_configs: [{
				role: "node"
			}]
			relabel_configs: [{
				action: "labelmap"
				regex:  "__meta_kubernetes_node_label_(.+)"
			}, {
				target_label: "__address__"
				replacement:  "kubernetes.default.svc:443"
			}, {
				source_labels: ["__meta_kubernetes_node_name"]
				regex:        "(.+)"
				target_label: "__metrics_path__"
				replacement:  "/api/v1/nodes/${1}/proxy/metrics"
			}]
		}, {
			// Scrape config for Kubelet cAdvisor.
			//
			// This is required for Kubernetes 1.7.3 and later, where cAdvisor metrics
			// (those whose names begin with 'container_') have been removed from the
			// Kubelet metrics endpoint.  This job scrapes the cAdvisor endpoint to
			// retrieve those metrics.
			//
			// In Kubernetes 1.7.0-1.7.2, these metrics are only exposed on the cAdvisor
			// HTTP endpoint; use "replacement: /api/v1/nodes/${1}:4194/proxy/metrics"
			// in that case (and ensure cAdvisor's HTTP server hasn't been disabled with
			// the --cadvisor-port=0 Kubelet flag).
			//
			// This job is not necessary and should be removed in Kubernetes 1.6 and
			// earlier versions, or it will cause the metrics to be scraped twice.
			job_name: "kubernetes-cadvisor"
			// Default to scraping over https. If required, just disable this or change to
			// `http`.
			scheme: "https"
			// This TLS & bearer token file config is used to connect to the actual scrape
			// endpoints for cluster components. This is separate to discovery auth
			// configuration because discovery & scraping are two separate concerns in
			// Prometheus. The discovery auth config is automatic if Prometheus runs inside
			// the cluster. Otherwise, more config options have to be provided within the
			// <kubernetes_sd_config>.
			tls_config: ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
			bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
			kubernetes_sd_configs: [{
				role: "node"
			}]
			relabel_configs: [{
				action: "labelmap"
				regex:  "__meta_kubernetes_node_label_(.+)"
			}, {
				target_label: "__address__"
				replacement:  "kubernetes.default.svc:443"
			}, {
				source_labels: ["__meta_kubernetes_node_name"]
				regex:        "(.+)"
				target_label: "__metrics_path__"
				replacement:  "/api/v1/nodes/${1}/proxy/metrics/cadvisor"
			}]
		}, {
			// Scrape config for service endpoints.
			//
			// The relabeling allows the actual service scrape endpoint to be configured
			// via the following annotations:
			//
			// * `prometheus.io/scrape`: Only scrape services that have a value of `true`
			// * `prometheus.io/scheme`: If the metrics endpoint is secured then you will need
			// to set this to `https` & most likely set the `tls_config` of the scrape config.
			// * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
			// * `prometheus.io/port`: If the metrics are exposed on a different port to the
			// service then set this appropriately.
			job_name: "kubernetes-service-endpoints"
			kubernetes_sd_configs: [{
				role: "endpoints"
			}]
			relabel_configs: [{
				source_labels: ["__meta_kubernetes_service_annotation_prometheus_io_scrape"]
				action: "keep"
				regex:  true
			}, {
				source_labels: ["__meta_kubernetes_service_annotation_prometheus_io_scheme"]
				action:       "replace"
				target_label: "__scheme__"
				regex:        "(https?)"
			}, {
				source_labels: ["__meta_kubernetes_service_annotation_prometheus_io_path"]
				action:       "replace"
				target_label: "__metrics_path__"
				regex:        "(.+)"
			}, {
				source_labels: ["__address__", "__meta_kubernetes_service_annotation_prometheus_io_port"]
				action:       "replace"
				target_label: "__address__"
				regex:        "([^:]+)(?::\\d+)?;(\\d+)"
				replacement:  "$1:$2"
			}, {
				action: "labelmap"
				regex:  "__meta_kubernetes_service_label_(.+)"
			}, {
				source_labels: ["__meta_kubernetes_namespace"]
				action:       "replace"
				target_label: "kubernetes_namespace"
			}, {
				source_labels: ["__meta_kubernetes_service_name"]
				action:       "replace"
				target_label: "kubernetes_name"
			}]
		}, {
			// Example scrape config for probing services via the Blackbox Exporter.
			//
			// The relabeling allows the actual service scrape endpoint to be configured
			// via the following annotations:
			//
			// * `prometheus.io/probe`: Only probe services that have a value of `true`
			job_name:     "kubernetes-services"
			metrics_path: "/probe"
			params: module: ["http_2xx"]
			kubernetes_sd_configs: [{
				role: "service"
			}]
			relabel_configs: [{
				source_labels: ["__meta_kubernetes_service_annotation_prometheus_io_probe"]
				action: "keep"
				regex:  true
			}, {
				source_labels: ["__address__"]
				target_label: "__param_target"
			}, {
				target_label: "__address__"
				replacement:  "blackbox-exporter.example.com:9115"
			}, {
				source_labels: ["__param_target"]
				target_label: "app"
			}, {
				action: "labelmap"
				regex:  "__meta_kubernetes_service_label_(.+)"
			}, {
				source_labels: ["__meta_kubernetes_namespace"]
				target_label: "kubernetes_namespace"
			}, {
				source_labels: ["__meta_kubernetes_service_name"]
				target_label: "kubernetes_name"
			}]
		}, {
			// Example scrape config for probing ingresses via the Blackbox Exporter.
			//
			// The relabeling allows the actual ingress scrape endpoint to be configured
			// via the following annotations:
			//
			// * `prometheus.io/probe`: Only probe services that have a value of `true`
			job_name:     "kubernetes-ingresses"
			metrics_path: "/probe"
			params: module: ["http_2xx"]
			kubernetes_sd_configs: [{
				role: "ingress"
			}]
			relabel_configs: [{
				source_labels: ["__meta_kubernetes_ingress_annotation_prometheus_io_probe"]
				action: "keep"
				regex:  true
			}, {
				source_labels: ["__meta_kubernetes_ingress_scheme", "__address__", "__meta_kubernetes_ingress_path"]
				regex:        "(.+);(.+);(.+)"
				replacement:  "${1}://${2}${3}"
				target_label: "__param_target"
			}, {
				target_label: "__address__"
				replacement:  "blackbox-exporter.example.com:9115"
			}, {
				source_labels: ["__param_target"]
				target_label: "app"
			}, {
				action: "labelmap"
				regex:  "__meta_kubernetes_ingress_label_(.+)"
			}, {
				source_labels: ["__meta_kubernetes_namespace"]
				target_label: "kubernetes_namespace"
			}, {
				source_labels: ["__meta_kubernetes_ingress_name"]
				target_label: "kubernetes_name"
			}]
		}, {
			// Example scrape config for pods
			//
			// The relabeling allows the actual pod scrape endpoint to be configured via the
			// following annotations:
			//
			// * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
			// * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
			// * `prometheus.io/port`: Scrape the pod on the indicated port instead of the
			// pod's declared ports (default is a port-free target if none are declared).
			job_name: "kubernetes-pods"
			kubernetes_sd_configs: [{
				role: "pod"
			}]
			relabel_configs: [{
				source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
				action: "keep"
				regex:  true
			}, {
				source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
				action:       "replace"
				target_label: "__metrics_path__"
				regex:        "(.+)"
			}, {
				source_labels: ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
				action:       "replace"
				regex:        "([^:]+)(?::\\d+)?;(\\d+)"
				replacement:  "$1:$2"
				target_label: "__address__"
			}, {
				action: "labelmap"
				regex:  "__meta_kubernetes_pod_label_(.+)"
			}, {
				source_labels: ["__meta_kubernetes_namespace"]
				action:       "replace"
				target_label: "kubernetes_namespace"
			}, {
				source_labels: ["__meta_kubernetes_pod_name"]
				action:       "replace"
				target_label: "kubernetes_pod_name"
			}]
		}]
	}
}
