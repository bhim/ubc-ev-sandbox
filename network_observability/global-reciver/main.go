package main

import (
	"compress/gzip"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	collectorlogspb "go.opentelemetry.io/proto/otlp/collector/logs/v1"
	collectormetricpb "go.opentelemetry.io/proto/otlp/collector/metrics/v1"
	collectortracepb "go.opentelemetry.io/proto/otlp/collector/trace/v1"
	commonpb "go.opentelemetry.io/proto/otlp/common/v1"
	metricpb "go.opentelemetry.io/proto/otlp/metrics/v1"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
)

func main() {

	var addr string
	addr = os.Getenv("HOST_ADDRESS")
	if addr == "" {
		addr = "0.0.0.0:6060"
	}
	mux := http.NewServeMux()

	mux.HandleFunc("/v1/traces", handleTraces)
	mux.HandleFunc("/v1/metrics", handleMetrics)
	mux.HandleFunc("/v1/logs", handleLogs)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OTLP receiver; POST to /v1/traces, /v1/metrics, /v1/logs\n"))
	})

	log.Printf("Listening on %s", addr)

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}

func readBody(r *http.Request) ([]byte, error) {
	defer r.Body.Close()
	body := r.Body

	if r.Header.Get("Content-Encoding") == "gzip" {

		gz, err := gzip.NewReader(r.Body)
		if err != nil {
			return nil, err
		}
		body = gz
	}
	return io.ReadAll(body)
}

func handleTraces(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	body, err := readBody(r)
	if err != nil {
		log.Printf("Error reading body for traces: %s", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	req := &collectortracepb.ExportTraceServiceRequest{}
	if err = proto.Unmarshal(body, req); err != nil {
		log.Printf("Error unmarshalling trace request: %s", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	jsonBytes, err := protojson.Marshal(req)
	fmt.Printf("Received trace request: %s\n", string(jsonBytes))
	//printTrace(req)
	w.WriteHeader(http.StatusOK)
}

func printTrace(req *collectortracepb.ExportTraceServiceRequest) {

	for _, resource := range req.ResourceSpans {
		for _, scop := range resource.ScopeSpans {
			for _, span := range scop.Spans {
				name := span.GetName()
				tid := span.GetTraceId()
				sid := span.GetSpanId()
				attrs := ""
				if len(span.Attributes) > 0 {
					var parts []string
					for _, attr := range span.Attributes {
						parts = append(parts, fmt.Sprintf("%s:%v", attr.Key, attrValue(attr.Value)))
					}
					attrs = " " + strings.Join(parts, ",")
				}
				log.Printf("[TRACE] span=%s traceId=%x spanId=%x%s", name, tid, sid, attrs)

			}
		}
	}
}

func handleMetrics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	body, err := readBody(r)
	if err != nil {
		log.Printf("Error reading body for metrics: %s", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	req := &collectormetricpb.ExportMetricsServiceRequest{}
	if err = proto.Unmarshal(body, req); err != nil {
		log.Printf("Error unmarshalling metrics request: %s", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	jsonBytes, err := protojson.Marshal(req)
	fmt.Printf("Received matric request: %s\n", string(jsonBytes))
	//printMetrics(req)
	w.WriteHeader(http.StatusOK)
}

func printMetrics(req *collectormetricpb.ExportMetricsServiceRequest) {
	for _, rm := range req.ResourceMetrics {
		for _, sm := range rm.ScopeMetrics {
			for _, m := range sm.Metrics {
				name := m.Name
				switch d := m.Data.(type) {
				case *metricpb.Metric_Sum:
					for _, pt := range d.Sum.DataPoints {
						attrs := attrMap(pt.Attributes)
						log.Printf("[METRIC] name=%s sum=%v attrs=%v", name, pt.Value, attrs)
					}
				case *metricpb.Metric_Gauge:
					for _, pt := range d.Gauge.DataPoints {
						attrs := attrMap(pt.Attributes)
						log.Printf("[METRIC] name=%s gauge=%v attrs=%v", name, pt.Value, attrs)
					}
				default:
					log.Printf("[METRIC] name=%s (other type)", name)
				}
			}
		}
	}
}

func handleLogs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	body, err := readBody(r)
	if err != nil {
		log.Printf("[logs] read body: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	req := &collectorlogspb.ExportLogsServiceRequest{}
	if err := proto.Unmarshal(body, req); err != nil {
		log.Printf("[logs] unmarshal: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	jsonBytes, err := protojson.Marshal(req)
	fmt.Printf("Received logs request: %s\n", string(jsonBytes))
	//printLogs(req)
	w.WriteHeader(http.StatusOK)
}

func printLogs(req *collectorlogspb.ExportLogsServiceRequest) {
	for _, rl := range req.ResourceLogs {
		for _, sl := range rl.ScopeLogs {
			for _, lr := range sl.LogRecords {
				bodyStr := ""
				if lr.Body != nil {
					bodyStr = lr.Body.GetStringValue()
				}
				attrs := attrMap(lr.Attributes)
				log.Printf("[LOG] body=%q time=%v attrs=%v", bodyStr, lr.TimeUnixNano, attrs)
			}
		}
	}
}
func attrValue(v *commonpb.AnyValue) string {
	if v == nil {
		return ""
	}
	switch x := v.Value.(type) {
	case *commonpb.AnyValue_StringValue:
		return x.StringValue
	case *commonpb.AnyValue_IntValue:
		return fmt.Sprintf("%d", x.IntValue)
	case *commonpb.AnyValue_DoubleValue:
		return fmt.Sprintf("%g", x.DoubleValue)
	case *commonpb.AnyValue_BoolValue:
		return fmt.Sprintf("%t", x.BoolValue)
	default:
		return fmt.Sprintf("%v", v.Value)
	}
}

func attrMap(attrs []*commonpb.KeyValue) map[string]string {
	out := make(map[string]string)
	for _, a := range attrs {
		if a != nil {
			out[a.Key] = attrValue(a.Value)
		}
	}
	return out
}
