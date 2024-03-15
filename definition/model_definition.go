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

type Choice struct {
	Value any
}

func (c Choice) GetValue(t string) string {
	if t == "string" {
		return fmt.Sprintf("%q", c.Value)
	}
	return fmt.Sprint(c.Value)
}

type Field struct {
	Name         string
	Type         string
	Optional     bool
	Repeated     bool
	Relationship bool
	ProtoIndex   int
	GormTag      string
	Choices      []Choice
}

func (f *Field) GetZeroValue() string {
	if f.Type == "string" {
		return ""
	}
	if f.Type == "uint64" {
		return "0"
	}
	return "nil"
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

type Model struct {
	Name           string
	Table          string
	Methods        allowedMethods
	Fields         []*Field
	CustomMethods  string
	CustomMessages string
}

func (m *Model) HasGet() bool {
	return m.Methods&Get > 0
}

func (m *Model) HasList() bool {
	return m.Methods&List > 0
}

func (m *Model) HasCreate() bool {
	return m.Methods&Create > 0
}

func (m *Model) HasUpdate() bool {
	return m.Methods&Update > 0
}

func (m *Model) HasDelete() bool {
	return m.Methods&Delete > 0
}

func (m *Model) AutoFillProtoIndex() {
	for i, f := range m.Fields {
		if f.ProtoIndex == 0 {
			f.ProtoIndex = i + 4
		}
	}
}

func (m *Model) GenerateDBModel() error {
	t := template.Must(template.ParseFiles(getFilePath("model.go.tpl")))
	outFile, err := os.Create("./internal/models/" + strings.ToLower(m.Name) + ".go")
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

func (m *Model) GenerateService() error {
	t := template.Must(template.ParseFiles(getFilePath("service.go.tpl")))
	outFile, err := os.Create("./internal/services/" + strings.ToLower(m.Name) + ".go")
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, m)
}

func (m *Model) LowercaseName() string {
	return strings.ToLower(m.Name)
}

func (m *Model) SnakeCaseName() string {
	return strcase.ToSnake(m.Name)
}

type ModelGenerator struct {
	Models         []*Model
	CustomMethods  string
	CustomMessages string
}

func (m *ModelGenerator) readCustomBlocks() {
	path := "./api/iot_collector_service.proto"
	f, err := os.ReadFile(path)
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

func (g *ModelGenerator) GenerateServiceProto() error {
	t := template.Must(template.ParseFiles(getFilePath("service.proto.tpl")))
	outFile, err := os.Create("./api/iot_collector_service.proto")
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, g)
}

func (g *ModelGenerator) GenerateServer() error {
	t := template.Must(template.ParseFiles(getFilePath("server.go.tpl")))
	outFile, err := os.Create("./internal/server/server_generated.go")
	if err != nil {
		return err
	}
	defer outFile.Close()
	return t.Execute(outFile, g)
}

func (g *ModelGenerator) GenerateFiles() error {
	g.readCustomBlocks()
	if err := g.GenerateServiceProto(); err != nil {
		return err
	}
	if err := g.GenerateServer(); err != nil {
		return err
	}
	for _, m := range g.Models {
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

func getFilePath(name string) string {
	_, dir, _, _ := runtime.Caller(0)
	dirName := filepath.Dir(dir)
	return filepath.Join(dirName, name)
}