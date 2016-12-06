$redis = Redis.new(url: ENV["REDIS_URL"])
# $socketio_port = $redis.get('socketio-port')