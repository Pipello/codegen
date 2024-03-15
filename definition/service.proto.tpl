// GENERATED CODE: Use custom blocks

syntax = "proto3";

package main;

option go_package = "github.com/pipello/iot-device-register/api";

message Filter {
  string field = 1;
  string value = 2;
}

enum OrderByDirection {
  DESC = 0;
  ASC = 1;
}

message OrderBy {
  string field = 1;
  OrderByDirection direction = 2;
}
{{ range .Models }}
//TODO: Implement enums for choice types
message {{.Name}} {
  uint64 id = 1;
  string created_at = 2;
  string updated_at = 3;
{{- range $index, $field := .Fields}} 
  {{if $field.Optional}}optional {{end}}{{if $field.Repeated}}repeated {{end}}{{$field.Type}} {{$field.ToSnakeCase}} = {{$field.ProtoIndex}}; 
{{- end }}
}

message {{.Name}}Lookup {
  string id = 1;
}

{{ if .HasGet -}}
message Get{{.Name}}Request {
  {{.Name}}Lookup lookup = 1;
  repeated string includes = 2;
}

message Get{{.Name}}Response {
  {{.Name}} {{.SnakeCaseName}} = 1;
}
{{- end }}

{{ if .HasList -}}
message List{{.Name}}sRequest {
  repeated Filter filters = 1;
  OrderBy order_by = 2;
  repeated string includes = 3;
}

message List{{.Name}}sResponse {
  repeated {{.Name}} {{.SnakeCaseName}}s = 1;
}
{{- end }}

{{ if .HasCreate -}}
message Create{{.Name}}Request {
  {{.Name}} {{.SnakeCaseName}} = 1;
}

message Create{{.Name}}Response {
  {{.Name}} {{.SnakeCaseName}} = 1;
}
{{- end }}

{{ if .HasUpdate -}}
message Update{{.Name}}Request {
  {{.Name}}Lookup lookup = 1;
  {{.Name}} {{.SnakeCaseName}} = 2;
  repeated string update_mask = 3;
}

message Update{{.Name}}Response {
  {{.Name}} {{.SnakeCaseName}} = 1;
}
{{- end }}

{{ if .HasDelete -}}
message Delete{{.Name}}Request {
  {{.Name}}Lookup lookup = 1;
}

message Delete{{.Name}}Response {}
{{- end }}

{{- end -}}
// <Service::Block(additionalMessages)>
{{- .CustomMessages -}}
// </Service::Block(additionalMessages)>

service IotCollectorService {
{{- range .Models}}
  {{ if .HasGet -}}
  rpc Get{{.Name}}(Get{{.Name}}Request) returns (Get{{.Name}}Response) {}
  {{- end }}
  {{ if .HasList -}}
  rpc List{{.Name}}s(List{{.Name}}sRequest) returns (List{{.Name}}sResponse) {}
  {{- end }}
  {{ if .HasCreate -}}
  rpc Create{{.Name}}(Create{{.Name}}Request) returns (Create{{.Name}}Response) {}
  {{- end }}
  {{ if .HasUpdate -}}
  rpc Update{{.Name}}(Update{{.Name}}Request) returns (Update{{.Name}}Response) {}
  {{- end }}
  {{ if .HasDelete -}}
  rpc Delete{{.Name}}(Delete{{.Name}}Request) returns (Delete{{.Name}}Response) {}
  {{- end }}
{{- end }}
  // <Service::Block(additionalMethods)>
  {{- .CustomMethods -}}
  // </Service::Block(additionalMethods)>
}

