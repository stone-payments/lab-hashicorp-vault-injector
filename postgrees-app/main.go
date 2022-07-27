package main

import (
	"context"
	"fmt"
	"log"
	"os"

	pgproto3 "github.com/jackc/pgproto3/v2"
	"github.com/jackc/pgx/v4/pgxpool"
	funk "github.com/thoas/go-funk"
)

const (
	QUERY_CURRENT_DB  string = "select current_database()"
	QUERY_GET_VERSION string = "select version();"
	QUERY_RECOVERY    string = "SELECT pg_is_in_recovery();"
)

type DBConfig struct {
	dbUser     string
	dbPassword string
	dbName     string
	dbHost     string
	dbPort     string
}

type DatabaseWrapper struct {
	pool *pgxpool.Pool
}

func main() {
	log.Printf("Starting...")
	var cfg DBConfig
	var d DatabaseWrapper
	cfg.dbUser = os.Getenv("DATABASE_USER")
	cfg.dbPassword = os.Getenv("DATABASE_PASSWORD")
	//cfg.dbPort = os.Getenv("DATABASE_PORT")
	cfg.dbName = os.Getenv("DATABASE_NAME")
	cfg.dbHost = os.Getenv("DATABASE_HOST")

	// postgres://username:password@url.com:5432/dbName
	DB_DSN := fmt.Sprintf("postgres://%s:%s@%s/%s",
		cfg.dbUser,
		cfg.dbPassword,
		cfg.dbHost,
		//cfg.dbPort,
		cfg.dbName,
	)

	// Create DB pool
	dbPool, err := pgxpool.Connect(context.Background(), DB_DSN)
	if err != nil {
		log.Fatal("failed to open a DB connection: ", err)
	}
	d.pool = dbPool
	defer d.pool.Close()

	log.Printf(">> From k8s Secrets: [DATABASE_HOST - %s]", cfg.dbHost)
	log.Printf(">> From k8s Secrets: [DATABASE_NAME - %s]", cfg.dbName)
	log.Printf(">> From k8s Secrets: [DATABASE_USER - %s]", cfg.dbUser)

	Querying(d, QUERY_CURRENT_DB)
	Querying(d, QUERY_GET_VERSION)
	Querying(d, QUERY_RECOVERY)

	log.Printf("waiting validation...")
	for {
		select {}
	}
}

func Querying(d DatabaseWrapper, query string) {
	queryResp, err := d.pool.Query(context.Background(), query)
	if err != nil {
		log.Fatal("error while querying", err)
	}
	defer queryResp.Close()

	results := []map[string]interface{}{}

	fields := queryResp.FieldDescriptions()
	fieldNames := funk.Map(fields, func(x pgproto3.FieldDescription) string {
		return string(x.Name)
	}).([]string)

	for queryResp.Next() {
		rowValues := map[string]interface{}{}

		values, err := queryResp.Values()
		if err != nil {
			log.Fatal("error while getting values on query", err)
		}

		for index, column := range values {
			rowValues[fieldNames[index]] = column
		}
		results = append(results, rowValues)
	}

	for _, values := range results {
		for k, v := range values {
			log.Printf(">> From PostgreSQL: [%s - %s]", k, v)
		}
	}
}
