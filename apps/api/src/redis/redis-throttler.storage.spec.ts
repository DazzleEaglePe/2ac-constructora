import type Redis from 'ioredis';
import { describe, expect, it, vi } from 'vitest';
import { RedisThrottlerStorage } from './redis-throttler.storage';

describe('RedisThrottlerStorage', () => {
  it('uses an atomic Redis operation and returns Nest throttler timing fields in seconds', async () => {
    const evalScript = vi.fn().mockResolvedValue([21, 59_001, 1, 15_000]);
    const storage = new RedisThrottlerStorage({ eval: evalScript } as unknown as Redis);

    await expect(storage.increment('203.0.113.5', 60_000, 20, 15_000, 'default')).resolves.toEqual({
      totalHits: 21,
      timeToExpire: 60,
      isBlocked: true,
      timeToBlockExpire: 15,
    });

    expect(evalScript).toHaveBeenCalledOnce();
    expect(evalScript.mock.calls[0][1]).toBe(2);
    expect(evalScript.mock.calls[0][2]).toContain('a2c:throttle:default:203.0.113.5');
    expect(evalScript.mock.calls[0][3]).toContain(':blocked');
  });

  it('fails closed when Redis cannot evaluate the limiter script', async () => {
    const evalScript = vi.fn().mockRejectedValue(new Error('Redis unavailable'));
    const storage = new RedisThrottlerStorage({ eval: evalScript } as unknown as Redis);

    await expect(storage.increment('203.0.113.5', 60_000, 20, 0, 'default')).rejects.toThrow(
      'Redis unavailable',
    );
  });
});
