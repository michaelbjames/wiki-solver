package main

import (
    "fmt"
    "log"
    "database/sql"
    "os"
    _ "github.com/go-sql-driver/mysql"
    // "runtime/pprof"
    // "flag"
    // "io/ioutil"
    // "strings"
)

type wiki_node uint64

// var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")

func main() {
    // flag.Parse()
    // if *cpuprofile != "" {
    //     f, err := os.Create(*cpuprofile)
    //     if err != nil {
    //         log.Fatal(err)
    //     }
    //     pprof.StartCPUProfile(f)
    //     defer pprof.StopCPUProfile()
    //     defer f.Close()
    // }

    db, err := sql.Open("mysql", "root:notasecret@/wiki")
    if err != nil {
        fmt.Fprintf(os.Stderr,"----FATAL ERROR---\n")
        panic(err.Error())
    }
    defer db.Close()

    // _ = find_path(db, "Elizabeth_I_of_England", "Mersenne_prime")
    _ = find_path(db, "Renaissance_humanism", "Scholasticism")
    // _ = find_path(db, "Elizabeth_I_of_England", "Martyr")



    return
}

func find_path(db *sql.DB, start_name string, end_name string) (path []string) {
    queue := make(chan wiki_node)
    defer close(queue)

    var sequence []wiki_node
    distance := make(map[wiki_node]int)
    previous := make(map[wiki_node]wiki_node)
    // var current wiki_node
    tmp := []string{"a"}

    search_finished := false

    start := name_to_id(db, start_name)
    finish := name_to_id(db, end_name)
    fmt.Printf("%s(%d) -> %s(%d)\n", start_name, start, end_name, finish)

    distance[start] = 0
    go func() {queue <- start}()

    for {
        select {
        case current := <-queue:
            // fmt.Printf("current: %d\n", current)
            fmt.Printf(".")
            if current == finish {
                search_finished = true
                fmt.Printf("\nEnd found, building solution...\n")
                for current != start {
                    sequence = append(sequence, current)
                    current = previous[current]
                }
                sequence = append(sequence, start)
                for _,node := range sequence {
                    name := id_to_name(db, node)
                    path = append(path, name)
                    fmt.Printf("%s <- ", name)
                }
                return
            }
            
            node_neighbors := neighbors(db, current)
            for _, neighbor := range node_neighbors {
                // fmt.Printf("%d, ", neighbor)
                
                alt_dist := distance[current] + 1
                if distance[neighbor] == 0 { // so it must NOT be visited
                    go func(n wiki_node) { 
                        // fmt.Fprintf(os.Stderr, "(queuing %d)", n)
                        if !search_finished {
                            queue <- n
                        }
                    }(neighbor)
                }
                if distance[neighbor] == 0 || alt_dist < distance[neighbor] {
                    distance[neighbor] = alt_dist
                    previous[neighbor] = current
                }

            }
        }
    }

    return tmp
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
            // fmt.Fprintf(os.Stderr, "Error: %s\n", err.Error())
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
