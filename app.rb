# Dummy app.
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
