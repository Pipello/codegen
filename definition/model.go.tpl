// GENERATED CODE: DO NOT EDIT

package models

import (
    "database/sql"
    "gorm.io/gorm"
    "google.golang.org/protobuf/types/known/timestamppb"

	pb "{{.RepositoryName}}/api"
    "github.com/Pipello/codegen/definition"
)
{{ range $i, $field := .Fields}}
{{- if gt (len $field.Choices) 0 }}
var {{ $field.LowerCaseName }}Choices = []{{$field.GetGORMType}}{{"{"}}
    {{- range $j, $choice := .Choices }}
    {{ $choice.GetValue $field.GetGORMType }},
    {{- end }}
{{"}"}}
{{ end }}
{{- end }}
type {{.Name}} struct {
    gorm.Model
    {{- range .Fields}}
    {{.Name}} {{if .Repeated}}[]{{end}}{{if .Optional}}*{{end}}{{.GetGORMType}} `json:"{{.ToSnakeCase}}"{{if .GormTag}} gorm:"{{.GormTag}}"{{end}}`
    {{- end}}
}

func ({{.Name}}) TableName() string {
	return "{{.Table}}"
}

func (m *{{.Name}}) Validate(db *gorm.DB) error {
    // <Model::Block(validation)>
    {{- .CustomValidation -}}
    // </Model::Block(validation)>
    return nil
}

func (m *{{.Name}}) ToProto() *pb.{{.Name}} {
    if m == nil {
        return nil
    }
    {{- range .Fields -}} 
    {{- if and .Relationship .Repeated }}
    {{ .LowerCaseName }} := []*pb.{{.GetGORMType}}{}
    for _, item := range m.{{ .Name }} {
        {{ .LowerCaseName }} = append({{ .LowerCaseName }}, item.ToProto())
    }
    {{- end }}
    {{- end }}
    return &pb.{{.Name}}{
        Id:          uint64(m.ID),
        CreatedAt: timestamppb.New(m.CreatedAt),
        UpdatedAt: timestamppb.New(m.UpdatedAt),
        {{- range .Fields }}
        {{ .GoCamelCaseName }}: {{ .ValueToProto }},
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