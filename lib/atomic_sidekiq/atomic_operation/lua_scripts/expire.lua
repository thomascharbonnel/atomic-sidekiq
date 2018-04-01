local queue = KEYS[1]
local in_flight_key = KEYS[2]
local now = tonumber(ARGV[1])

local job = redis.call('get', in_flight_key)
if (not job) then return nil end

local expiration = tonumber(string.match(job, '"expire_at":([0-9]*)'))
if expiration > now then return nil end
job = string.gsub(job, ',?"expire_at":[0-9]*', '')

redis.call('lpush', queue, job)
redis.call('del', in_flight_key)

return { queue, job }
