// GENERATED CODE: DO NOT EDIT

package models

import (
	pb "iot-device-register/api"

	"gorm.io/gorm"
)
{{ range $i, $field := .Fields}}
{{- if gt (len $field.Choices) 0 }}
var {{ $field.LowerCaseName }}Choices = []{{$field.Type}}{{"{"}}
    {{- range $j, $choice := .Choices }}
    {{ $choice.GetValue $field.Type }},
    {{- end }}
{{"}"}}
{{ end }}
{{- end }}
type {{.Name}} struct {
    gorm.Model
    {{- range .Fields}}
    {{.Name}} {{if .Repeated}}[]{{end}}{{if .Optional}}*{{end}}{{.Type}} `json:"{{.ToSnakeCase}}"{{if .GormTag}} gorm:"{{.GormTag}}"{{end}}`
    {{- end}}
}

func ({{.Name}}) TableName() string {
	return "{{.Table}}"
}

func (m *{{.Name}}) IsValid() bool {
    {{- range .Fields}}
    {{- if gt (len .Choices) 0 }}
    if {{ if .Optional }}m.{{ .Name }} != nil && {{ end }}!SliceContains({{ if .Optional }}*{{ end }}m.{{ .Name }}, {{ .LowerCaseName }}Choices) {
        return false
    }
    {{- end }}
    {{- end }}
    return true
}

func (m *{{.Name}}) ToProto() *pb.{{.Name}} {
    if m == nil {
        return nil
    }
    {{- range .Fields -}} 
    {{- if and .Relationship .Repeated }}
    {{ .LowerCaseName }} := []*pb.{{.Type}}{}
    for _, item := range m.{{ .Name }} {
        {{ .LowerCaseName }} = append({{ .LowerCaseName }}, item.ToProto())
    }
    {{- end }}
    {{- end }}
    return &pb.{{.Name}}{
        Id:          uint64(m.ID),
        CreatedAt: m.CreatedAt.String(),
        UpdatedAt: m.UpdatedAt.String(),
        {{- range .Fields }} 
        {{ if not .Relationship -}}{{ .GoCamelCaseName }}: m.{{ .Name }},
        {{- else if not .Repeated -}}{{ .GoCamelCaseName }}: m.{{ .Name }}.ToProto(),
        {{- else }}{{ .GoCamelCaseName }}: {{ .LowerCaseName }},
        {{- end -}}
        {{- end }}
    }
}

func IsValid{{.Name}}Include(include string) bool {
    {{- range .Fields}}
    {{- if .Relationship }}
    if include == "{{ .Name }}" {
        return true
    }
    {{- end }}
    {{- end }}
    return false
}