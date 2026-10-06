import { randomUUID } from 'node:crypto';
import type { ThrottlerStorage } from '@nestjs/throttler';
import Redis from 'ioredis';

type ThrottlerStorageRecord = {
  totalHits: number;
  timeToExpire: number;
  isBlocked: boolean;
  timeToBlockExpire: number;
};

const INCREMENT_SCRIPT = `
local nowParts = redis.call('TIME')
local now = (tonumber(nowParts[1]) * 1000) + math.floor(tonumber(nowParts[2]) / 1000)
local ttl = tonumber(ARGV[1])
local limit = tonumber(ARGV[2])
local blockDuration = tonumber(ARGV[3])
local member = tostring(now) .. ':' .. ARGV[4]

local blockTtl = redis.call('PTTL', KEYS[2])
if blockTtl > 0 then
  local hits = redis.call('ZCARD', KEYS[1])
  return { hits, math.max(0, redis.call('PTTL', KEYS[1])), 1, blockTtl }
end

redis.call('ZREMRANGEBYSCORE', KEYS[1], '-inf', now - ttl)
redis.call('ZADD', KEYS[1], now, member)
redis.call('PEXPIRE', KEYS[1], ttl)

local hits = redis.call('ZCARD', KEYS[1])
local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
local timeToExpire = math.max(0, tonumber(first[2]) + ttl - now)
local isBlocked = 0
local timeToBlockExpire = 0
if blockDuration > 0 and hits > limit then
  redis.call('PSETEX', KEYS[2], blockDuration, '1')
  isBlocked = 1
  timeToBlockExpire = blockDuration
end

return { hits, timeToExpire, isBlocked, timeToBlockExpire }
`;

/** Shared, atomic sliding-window storage for Nest's API rate limits. */
export class RedisThrottlerStorage implements ThrottlerStorage {
  constructor(private readonly redis: Redis) {}

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<ThrottlerStorageRecord> {
    const namespacedKey = `a2c:throttle:${throttlerName}:${key}`;
    const result = (await this.redis.eval(
      INCREMENT_SCRIPT,
      2,
      namespacedKey,
      `${namespacedKey}:blocked`,
      ttl,
      limit,
      blockDuration,
      randomUUID(),
    )) as [number | string, number | string, number | string, number | string];

    return {
      totalHits: Number(result[0]),
      timeToExpire: Math.ceil(Number(result[1]) / 1000),
      isBlocked: Number(result[2]) === 1,
      timeToBlockExpire: Math.ceil(Number(result[3]) / 1000),
    };
  }
}
