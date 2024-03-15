# codegen tool
This tool was originally designed for personal usage. It generates proto files, db model for GORM and gRPC functions based on a schema

## Create a command to use the codegen tool
```go
package main

import (
	"fmt"
	"path/to/schema"

	"github.com/Pipello/codegen/definition"
)

func main() {
	models := []*definition.Model{
		schema.MyModel(),
	}
	generator := definition.ModelGenerator{Models: models}
	err := generator.GenerateFiles()
	if err != nil {
		panic(err)
	}
	fmt.Println("CODEGEN: success")
}
```

## Schema
```go
package schema

import "github.com/Pipello/codegen/definition"

func Device() *definition.Model {
	m := &definition.Model{
		Name:    "MyModel",
		Table:   "models",
		Methods: definition.Get | definition.List | definition.Update | definition.Create,
		Fields: []*definition.Field{
			{Name: "Name", Type: "string"},
			{Name: "IsGenerated", Type: "bool"},
		},
	}
	m.AutoFillProtoIndex()
	return m
}
```

## Server
It is required to create a `server.go` file to register the actual server. A better solution for this should be implemented.
```go
package server

import (
	pb "yourrepo/api"
	"yourrepo/internal/services"

	"gorm.io/gorm"
)

type Server struct {
	pb.UnimplementedIotCollectorServiceServer
	myModelService *services.MyModelService
}

func NewServer(db *gorm.DB) *Server {
	return &Server{
		myModelService: services.NewMyModelService(db),
	}
}
```
