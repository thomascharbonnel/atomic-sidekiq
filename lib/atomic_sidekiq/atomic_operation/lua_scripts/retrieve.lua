local queue = KEYS[1]
local flight = KEYS[2]
local expire_at = tonumber(ARGV[1])

local job = redis.call('lpop', queue)
if (not job) then return nil end
job = job:sub(1,-2)..',"expire_at":'..expire_at.."}"

local flight_key = flight..queue..':'..string.match(job, '"jid":"([^"]*)"')
redis.call('set', flight_key, job)
return { queue, job }
