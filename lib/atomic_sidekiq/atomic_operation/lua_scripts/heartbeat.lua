local in_flight_key = KEYS[1]
local expire_at = ARGV[1]

local job = redis.call('get', in_flight_key)
if (not job) then return nil end

job = string.gsub(job, '("expire_at":)[0-9]*', '%1'..expire_at)
redis.call('set', in_flight_key, job)

return job
