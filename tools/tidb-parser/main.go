package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/pingcap/tidb/pkg/parser"
	_ "github.com/pingcap/tidb/pkg/parser/test_driver"
)

func main() {
	var sql string

	if len(os.Args) > 1 {
		sql = strings.Join(os.Args[1:], " ")
	} else {
		bytes, err := io.ReadAll(os.Stdin)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error reading stdin: %v\n", err)
			os.Exit(1)
		}
		sql = string(bytes)
	}

	sql = strings.TrimSpace(sql)
	if sql == "" {
		fmt.Fprintln(os.Stderr, "usage: tidb-parser <sql>  OR  echo <sql> | tidb-parser")
		os.Exit(1)
	}

	p := parser.New()
	stmts, _, err := p.Parse(sql, "", "")
	if err != nil {
		fmt.Fprintf(os.Stderr, "parse error: %v\n", err)
		os.Exit(1)
	}

	out, err := json.MarshalIndent(stmts, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "json error: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(string(out))
}
