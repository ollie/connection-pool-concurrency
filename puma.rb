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
