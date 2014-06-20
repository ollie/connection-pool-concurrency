# Configurations

* DB = Database
* RD = Redis

## 1

* DB connection limit: `20`
* No Redis
* Web: `1 dyno * 1 workers * 20 threads = 20 DB connections`
* Web: DB connection pool size: `20 (threads)`
* Unused DB connections: `0`

## 2

* DB connection limit: `20`
* No Redis
* Web: `1 dyno * 2 workers * 10 threads = 20 DB connections`
* Web: DB connection pool size: `10 (threads)`
* Unused DB connections: `0`

## 3

* DB connection limit: `20`
* RD connection limit: `10`
* Worker: `1 worker * 2 concurrency = 2 RD and DB connections`
* Worker: RD connection pool size: `2`
* Worker: DB connection pool size: `2`
* Web: `1 dyno * 2 workers * 9 threads = 18 DB connections`
* Web: DB connection pool size: `9 (threads)`
* Unused DB connections: `0`

## 4

* DB connection limit: `60`
* RD connection limit: `10`
* Worker: `2 worker * 5 concurrency = 10 RD and DB connections`
* Worker: RD connection pool size: `5`
* Worker: DB connection pool size: `5`
* Web: `2 dynos * 2 workers * 12 threads = 48 DB connections`
* Web: DB connection pool size: `12 (threads)`
* Unused DB connections: `2`
