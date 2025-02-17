package definition

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"text/template"
	"unicode"

	"github.com/iancoleman/strcase"
)

var customMethodsBlock = regexp.MustCompile(`<Service::Block\(additionalMethods\)>(?P<block>(\s\S*)*)\/\/\s*</Service::Block\(additionalMethods\)>`)
var customMessagesBlock = regexp.MustCompile(`<Service::Block\(additionalMessages\)>(?P<block>(\s\S*)*)\/\/\s*</Service::Block\(additionalMessages\)>`)
var customValidationBlock = regexp.MustCompile(`<Model::Block\(validation\)>(?P<block>(\s\S*)*)\/\/\s*</Model::Block\(validation\)>`)

type Choice struct {
	Value any
}

func (c Choice) GetValue(t string) string {
	if t == "string" {
		return fmt.Sprintf("%q", c.Value)
	}
	return fmt.Sprint(c.Value)
}

type FieldType int

const (
	IntegerType FieldType = iota
	UnsignedIntegerType
	StringType
	Timestamp
	Boolean
	Relationship
	FloatType
)

type Field struct {
	Name         string
	Type         FieldType
	Optional     bool
	Repeated     bool
	Relationship bool
	ProtoIndex   int
	GormTag      string
	Choices      []Choice
}

func (f *Field) GetProtoType() string {
	switch f.Type {
	case IntegerType:
		return "int64"
	case UnsignedIntegerType:
		return "uint64"
	case StringType:
		return "string"
	case Timestamp:
		return "google.protobuf.Timestamp"
	case Boolean:
		return "bool"
	case FloatType:
		return "float"
	}
	return ""
}

func (f *Field) GetGORMType() string {
	switch f.Type {
	case IntegerType:
		return "int64"
	case UnsignedIntegerType:
		return "uint64"
	case StringType:
		return "string"
	case Timestamp:
		return "sql.NullTime"
	case Boolean:
		return "bool"
	case FloatType:
		return "float32"
	}
	return ""
}

func (f *Field) ValueToProto() string {
	if f.Type == Timestamp {
		return "definition.SQLTimeToProto(m." + f.Name + ")"
	}

	if f.Relationship {
		if f.Repeated {
			return f.LowerCaseName()
		}
		return "m." + f.Name + ".ToProto()"
	}
	return "m." + f.Name
}

func (f *Field) ValueToSQL(model string) string {
	if f.Relationship {
		return ""
	}
	accessor := strings.Join([]string{"req", model, f.GoCamelCaseName()}, ".")
	if f.Type == Timestamp {
		return "definition.ProtoTimeToSql(" + accessor + ")"
	}
	return accessor
}

func (f *Field) GoCamelCaseName() string {
	prev := 'a'
	return strings.Map(
		func(r rune) rune {
			defer func() { prev = r }()
			if unicode.IsUpper(prev) && unicode.IsUpper(r) {
				return unicode.ToLower(r)
			}
			return r
		},
		f.Name,
	)
}

func (f *Field) LowerCaseName() string {
	return strings.ToLower(f.Name)
}

func (f *Field) ToSnakeCase() string {
	return strcase.ToSnake(f.Name)
}

type allowedMethods int

const (
	Get allowedMethods = 1 << iota
	List
	Create
	Update
	Delete
)

type Schema struct {
	Name             string
	Table            string
	Methods          allowedMethods
	Fields           []*Field
	CustomValidation string
	RepositoryName   string
}

func (m *Schema) HasGet() bool {
	return m.Methods&Get > 0
}

func (m *Schema) HasList() bool {
	return m.Methods&List > 0
}

func (m *Schema) HasCreate() bool {
	return m.Methods&Create > 0
}

func (m *Schema) HasUpdate() bool {
	return m.Methods&Update > 0
}

func (m *Schema) HasDelete() bool {
	return m.Methods&Delete > 0
}

func (m *Schema) AutoFillProtoIndex() {
	for i, f := range m.Fields {
		if f.ProtoIndex == 0 {
			f.ProtoIndex = i + 4
		}
	}
}

func (m *Schema) GenerateDBModel() error {
	t := template.Must(template.ParseFiles(getFilePath("model.go.tpl")))
	fileName := "./internal/models/" + strings.ToLower(m.Name) + ".go"
	m.readModelCustomBlock(fileName)
	outFile, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer outFile.Close()
	err = t.Execute(outFile, m)
	if err != nil {
		return err
	}
	return nil
}

func (m *Schema) readModelCustomBlock(path string) {
	f, err := os.ReadFile(path)
	if err != nil {
		return
	}
	fStr := string(f)
	if customValidationBlock.MatchString(fStr) {
		matches := customValidationBlock.FindStringSubmatch(fStr)
		m.CustomValidation = matches[customValidationBlock.SubexpIndex("block")]
	}
}

func (m *Schema) GenerateService() error {
	t := template.Must(template.ParseFiles(getFilePath("service.go.tpl")))
	fileName := "./internal/services/" + strings.ToLower(m.Name) + ".go"
	outFile, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, m)
}

func (m *Schema) LowercaseName() string {
	return strings.ToLower(m.Name)
}

func (m *Schema) SnakeCaseName() string {
	return strcase.ToSnake(m.Name)
}

type CompleteGenerator struct {
	Schemas        []*Schema
	Config         Config
	CustomMethods  string
	CustomMessages string
}

func (m *CompleteGenerator) getProtoServiceFilePath() string {
	return fmt.Sprintf("./api/%s.proto", strcase.ToSnake(m.Config.ServiceName))
}

func (m *CompleteGenerator) readCustomBlocks() {
	f, err := os.ReadFile(m.getProtoServiceFilePath())
	if err != nil {
		return
	}
	fStr := string(f)
	if customMethodsBlock.MatchString(fStr) {
		matches := customMethodsBlock.FindStringSubmatch(fStr)
		m.CustomMethods = matches[customMethodsBlock.SubexpIndex("block")]
	}
	if customMessagesBlock.MatchString(fStr) {
		matches := customMessagesBlock.FindStringSubmatch(fStr)
		m.CustomMessages = matches[customMessagesBlock.SubexpIndex("block")]
	}
}

func (g *CompleteGenerator) GenerateServiceProto() error {
	t := template.Must(template.ParseFiles(getFilePath("service.proto.tpl")))
	outFile, err := os.Create(g.getProtoServiceFilePath())
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, g)
}

func (g *CompleteGenerator) GenerateServer() error {
	t := template.Must(template.ParseFiles(getFilePath("server.go.tpl")))
	outFile, err := os.Create("./internal/server/server_generated.go")
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, g)
}

func (g *CompleteGenerator) GenerateFiles() error {
	g.readCustomBlocks()
	if err := g.GenerateServiceProto(); err != nil {
		return err
	}
	if err := g.GenerateServer(); err != nil {
		return err
	}
	for _, m := range g.Schemas {
		m.RepositoryName = g.Config.RepositoryName
		err := m.GenerateDBModel()
		if err != nil {
			return err
		}
		err = m.GenerateService()
		if err != nil {
			return err
		}
	}
	return nil
}

func (g *CompleteGenerator) Generate() error {
	return g.GenerateFiles()
}

func getFilePath(name string) string {
	_, dir, _, _ := runtime.Caller(0)
	dirName := filepath.Dir(dir)
	return filepath.Join(dirName, name)
}

type Config struct {
	ServiceName     string
	GRPCServiceName string
	RepositoryName  string
}

type Generator interface {
	Generate() error
}

func NewGenerator(schemas []*Schema, config Config) Generator {
	return &CompleteGenerator{
		Schemas: schemas,
		Config:  config,
	}
}
