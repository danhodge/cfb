worker_processes 2

before_fork do |_server, _worker|
  sleep 1
end
