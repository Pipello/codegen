// GENERATED CODE: DO NOT EDIT

package services

import (
	"fmt"
	"context"
	"errors"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"gorm.io/gorm"

	pb "{{.RepositoryName}}/api"
	"{{.RepositoryName}}/internal/models"
	"github.com/Pipello/codegen/definition"
)
{{ $modelName := .Name }}
type {{$modelName}}Service struct {
    db *gorm.DB
}

func New{{$modelName}}Service(db *gorm.DB) *{{$modelName}}Service {
    return &{{$modelName}}Service{
        db: db,
    }
}
{{ if .HasGet -}}
func (s *{{$modelName}}Service) Get(ctx context.Context, req *pb.Get{{$modelName}}Request) (*models.{{$modelName}}, error) {
    var item models.{{$modelName}}
	query := s.db.Model(&models.{{$modelName}}{})

	for _, include := range req.Includes {
		if models.IsValid{{$modelName}}Include(include) {
			query = query.Preload(include)
		}
	}
	err := query.Where("id = ?", req.Lookup.Id).First(&item).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Error(codes.NotFound, "item not found")
		}

		return nil, status.Error(codes.Internal, "unexpected error")
	}
	return &item, nil
}
{{ end -}}
{{ if .HasList -}}
func (s *{{$modelName}}Service) List(ctx context.Context, req *pb.List{{$modelName}}sRequest) ([]models.{{$modelName}}, error) {
    var items []models.{{$modelName}}

	query := s.db.Model(&models.{{$modelName}}{})
	for _, include := range req.Includes {
		if models.IsValid{{$modelName}}Include(include) {
			query = query.Preload(include)
		}
	}
	//TODO: make filter and sort SQL injection safe
	for _, filter := range req.Filters {
		query = query.Where(filter.Field + " = ?", filter.Value)
	}
	if req.OrderBy != nil {
		direction := pb.OrderByDirection_name[int32(req.OrderBy.Direction)]
		query = query.Order(fmt.Sprintf("%s %s", req.OrderBy.Field, direction))
	}

	err := query.Find(&items).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Error(codes.NotFound, "item not found")
		}

		return nil, status.Error(codes.Internal, "unexpected error")
	}
	return items, nil
}
{{ end -}}
{{ if .HasCreate -}}
func (s *{{$modelName}}Service) Create(ctx context.Context, req *pb.Create{{$modelName}}Request) (*models.{{$modelName}}, error) {
	item := models.{{$modelName}}{
        {{- range $index, $field := .Fields}} 
        {{if not $field.Relationship}}{{$field.Name}}: {{ $field.ValueToSQL $modelName }},{{end}}
        {{- end }}
	}
	if err := item.Validate(s.db); err != nil {
		return nil, status.Error(codes.InvalidArgument,
		 fmt.Sprintf("{{$modelName}} is not valid, %v", err))
	}
	if err := s.db.Create(&item).Error; err != nil {
		return nil, status.Error(codes.Internal, "unexpected error")
	}
	return &item, nil
}
{{ end -}}
{{ if .HasUpdate -}}
func (s *{{$modelName}}Service) Update(ctx context.Context, req *pb.Update{{$modelName}}Request) (*models.{{$modelName}}, error) {
	var item models.{{$modelName}}
	err := s.db.Where("id = ?", req.Lookup.Id).First(&item).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Error(codes.NotFound, "item not found")
		}
		return nil, status.Error(codes.Internal, "unexpected error")
	}

	// TODO: more granularity on updatable fields
	for _, field := range req.UpdateMask {
		switch field {
		{{- range $index, $field := .Fields }}
		{{- if not $field.Relationship }}
		case "{{ $field.ToSnakeCase }}":
			item.{{ $field.Name }} = {{ $field.ValueToSQL $modelName }}
		{{- end }}
		{{- end }}
		}
	}
	if err := item.Validate(s.db); err != nil {
		return nil, status.Error(codes.InvalidArgument, 
		fmt.Sprintf("{{$modelName}} is not valid, %v", err))
	}
	err = s.db.Save(&item).Error
	if err != nil {
		return nil, status.Error(codes.Internal, "unexpected error")
	}
	return &item, nil
}
{{ end -}}
{{ if .HasDelete -}}
func (s *{{$modelName}}Service) Delete(ctx context.Context, req *pb.Delete{{$modelName}}Request) error {
	err := s.db.Unscoped().Delete(&models.{{$modelName}}{}, req.Lookup.Id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return status.Error(codes.NotFound, "item not found")
		}

		return status.Error(codes.Internal, "unexpected error")
	}
	return nil
}
{{ end -}}