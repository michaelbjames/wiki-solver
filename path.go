package main

import (
    "fmt"
    "log"
    "database/sql"
    "os"
    _ "github.com/go-sql-driver/mysql"
    // "io/ioutil"
    // "strings"
)

type wiki_node uint64

func main() {
    db, err := sql.Open("mysql", "root:notasecret@/wiki")
    switch {
    case err != nil:
        fmt.Fprintf(os.Stderr,"----FATAL ERROR---\n")
        log.Fatal(err)
        return
    }
    defer db.Close()

    // path := find_path("","")
    // for i := 0; i < len(path); i++ {
    //     fmt.Printf("%s",path[i])
    // }

    test1 := id_to_name(db, 10128)
    fmt.Printf("%s\n",test1)
    test2 := name_to_id(db,"Elizabeth_I_of_England")
    fmt.Printf("%d\n",test2)
    test3 := neighbors(db, 10128)
    for i := 0; i < len(test3); i++ {
        fmt.Printf("%d\n", test3[i])
    }

    return
}

func find_path(start_name string, end_name string) (path []string) {
    empty_path := []string{}
    fmt.Printf("Hello World")
    return empty_path
}

func neighbors(db *sql.DB, source wiki_node) (neighbors []wiki_node) {
    stmt, err := db.Prepare("SELECT to_id FROM links WHERE from_id=?")
    if err != nil {
        panic(err.Error())
    }
    defer stmt.Close()

    var rows *sql.Rows
    rows, err = stmt.Query(source)
    defer rows.Close()

    if err := rows.Err(); err != nil {
        panic(err.Error())
    }
    for rows.Next() {
        var neighbor wiki_node
        if err := rows.Scan(&neighbor); err != nil {
            fmt.Fprintf(os.Stderr, "Error: %s\n", err.Error())
        } else {
            neighbors = append(neighbors,neighbor)  
        }
    }

    return
}

func id_to_name(db *sql.DB, page_id wiki_node) (name string) {
    stmt, err := db.Prepare("SELECT page_title FROM page WHERE page_id=?")
    if err != nil {
        panic(err.Error())
    }
    defer stmt.Close()

    err = stmt.QueryRow(page_id).Scan(&name)
    switch {
    case err == sql.ErrNoRows:
        log.Printf("No page with that ID.")
    case err != nil:
        log.Fatal(err)
    }
    return
}

func name_to_id(db *sql.DB, name string) (page_id wiki_node) {
    stmt, err := db.Prepare("SELECT page_id FROM page WHERE page_title=?")
    if err != nil {
        panic(err.Error())
    }
    defer stmt.Close()

    err = stmt.QueryRow(name).Scan(&page_id)
    switch {
    case err == sql.ErrNoRows:
        log.Printf("No page with that Name.")
    case err != nil:
        log.Fatal(err)
    }
    return
}
