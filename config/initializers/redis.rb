REDIS_URL = ENV.fetch('REDIS_URL', 'redis://redis:6379/1')
$redis = Redis.new(url: REDIS_URL)
