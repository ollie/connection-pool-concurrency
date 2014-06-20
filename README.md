# Puma, Sequel, Heroku, Connection Pool and Concurrency

How many database connections will I need?
How do I figure out connection pool size?
Consider a Heroku setup like this:

* 2 dynos (machines),
* Each of them has 4 Puma workers (processes),
* And each worker has max 10 threads.

To get the number of connections your app can eat when running at max:

* Max database connections: `2 dynos * 4 workers * 10 threads = 80 connections`

Now you need to figure out how to correctly set connection pool size so
each part has its own share but the total doesn't exceed the connection limit.
Every worker (process) has its own pool.

* Number of pools: `2 dynos * 4 workers = 8 pools in total`
* Connection pool: `10 threads = 10 connections`
* Total:           `8 pools * 10 connections = 80 connections` (to make sure)

## I want to tweak setup and pool size

If you are using Postgres Hobby Basic plan, you have 20 connections limit (https://addons.heroku.com/heroku-postgresql).
You will need to tweak your setup so that it will use at most 20 connections.

    2 dynos * 2 workers * 5 thread   = 20 connections (pool is 5)
    1 dyno  * 2 workers * 10 threads = 20 connections (pool is 10)
    1 dyno  * 1 worker  * 20 threads = 20 connections (pool is 20)
    ...

## Experiment

    $ git clone <this-repo>
    $ cd <this-repo>
    $ bundle
    $ rake db:create
    $ rake s # to start server

Open another tab

    $ rake b # to start benchmark (wrk)

* Play with `min_threads`, `max_threads` and `workers` in `puma.rb`.
* Also play with `max_connections` in `app.rb`.
* Benchmark settings are in `Rakefile`.

Setting connection pool too low may cause `Sequel::PoolTimeout - Sequel::PoolTimeout` errors.

## Beware when using more workers (processes)

When using multiple workers, you need to disconnect the connections from the pool
before the process fork occurs. This is done with `on_worker_boot` in Puma.
See `puma.rb`.

If you don't clear the pool, you might end up with `Sequel::DatabaseDisconnectError - PG::UnableToSend: socket not open`
and `Timeout::Error - execution expired` errors.

## Sidekiq

* Concurrency option: connection limit / sidekiq workers

If you are using Redis to Go Nano, then you have 10 connections limit (https://addons.heroku.com/redistogo).
And if you are using 1 (sidekiq) worker, then your concurrency is 10.
If 2 workers, then 5.

    sidekiq -c 10 # if limit 10 and 1 worker
    sidekiq -c 5  # if limit 10 and 2 workers

Each of those jobs may use a database connection! So make sure to subtract it from the database connection limit.

## Links

* Heroku article: https://devcenter.heroku.com/articles/concurrency-and-database-connections
* Forking webserver: http://sequel.jeremyevans.net/rdoc/files/doc/code_order_rdoc.html
* Sequel Talk: https://groups.google.com/forum/#!topic/sequel-talk/lrKLmgyOWOU
* Sequel connection pool options: http://sequel.jeremyevans.net/rdoc/classes/Sequel/ThreadedConnectionPool.html
* Sequel connection validator plugin: http://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
* Puma config: https://github.com/puma/puma/blob/master/examples/config.rb
* Sidekiq with Memcached connection pool https://github.com/mperham/sidekiq/wiki/Advanced-Options

## Code

`puma.rb`

    setup = {
      env:          ENV['RACK_ENV']         || 'development',
      port:        (ENV['PORT']             || 9292).to_i,
      min_threads: (ENV['PUMA_MIN_THREADS'] || 10).to_i,
      max_threads: (ENV['PUMA_MAX_THREADS'] || 10).to_i,
      workers:     (ENV['PUMA_WORKERS']     || 2).to_i
    }

    port        setup[:port]
    environment setup[:env]
    workers     setup[:workers]
    threads     setup[:min_threads], setup[:max_threads]

    preload_app!

    on_worker_boot do
      # Disconnect the Sequel connection pool so new connections are created.
      App.db.disconnect
    end

`app.rb`

    class App < Sinatra::Base
      configure do
        db = Sequel.connect(
          'postgres://localhost/sequel_test',
          max_connections: 20
        )

        db.extension :connection_validator

        set :db, db
        set :logging, true
      end

      get '/' do
        settings.db.run('SELECT pg_sleep(0.5)')
        'Hello'
      end
    end

Server

    RACK_ENV=production puma -C puma.rb

Benchmark

    wrk -t 30 -c 300 -d 2s http://127.0.0.1:9292/
