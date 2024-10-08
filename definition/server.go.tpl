// GENERATED CODE: DO NOT EDIT

package server

import (
	"context"
	pb "{{.Config.RepositoryName}}/api"
)


{{ range .Schemas }}
// {{.Name}} methods

{{ if .HasGet -}}
func (s *Server) Get{{.Name}}(ctx context.Context, req *pb.Get{{.Name}}Request) (*pb.Get{{.Name}}Response, error) {
    item, err := s.{{.LowercaseName}}Service.Get(ctx, req)
    if err != nil {
        return nil, err
    }
	return &pb.Get{{.Name}}Response{
        {{.Name}}: item.ToProto(),
    }, nil
}
{{ end -}}
{{ if .HasList -}}
func (s *Server) List{{.Name}}s(ctx context.Context, req *pb.List{{.Name}}sRequest) (*pb.List{{.Name}}sResponse, error) {
	items, err := s.{{.LowercaseName}}Service.List(ctx, req)
    if err != nil {
        return nil, err
    }
    protoItems := []*pb.{{.Name}}{}
    for _, item := range items {
        protoItems = append(protoItems, item.ToProto())
    }
    return &pb.List{{.Name}}sResponse{
        {{.Name}}s: protoItems,
    }, nil
}
{{ end -}}
{{ if .HasCreate -}}
func (s *Server) Create{{.Name}}(ctx context.Context, req *pb.Create{{.Name}}Request) (*pb.Create{{.Name}}Response, error) {
	item, err := s.{{.LowercaseName}}Service.Create(ctx, req)
    if err != nil {
        return nil, err
    }
	return &pb.Create{{.Name}}Response{
        {{.Name}}: item.ToProto(),
    }, nil
}
{{ end -}}
{{ if .HasUpdate -}}
func (s *Server) Update{{.Name}}(ctx context.Context, req *pb.Update{{.Name}}Request) (*pb.Update{{.Name}}Response, error) {
	item, err := s.{{.LowercaseName}}Service.Update(ctx, req)
    if err != nil {
        return nil, err
    }
	return &pb.Update{{.Name}}Response{
        {{.Name}}: item.ToProto(),
    }, nil
}
{{ end -}}
{{ if .HasDelete -}}
func (s *Server) Delete{{.Name}}(ctx context.Context, req *pb.Delete{{.Name}}Request) (*pb.Delete{{.Name}}Response, error) {
    err := s.{{.LowercaseName}}Service.Delete(ctx, req)
    if err != nil {
        return nil, err
    }
	return &pb.Delete{{.Name}}Response{}, nil
}
{{ end -}}
{{ end }}