import AcmePlatform
import Foundation
import Testing

@Suite struct KitCachingTests {
    @Test func evictsTheOldestEntry() throws {
        let cache: Kit.Caching.TTLCache<String> = Kit.Caching.newTTLCache(2, ttl: 60, clock: Kit.Clocks.FixedClock(at: 1000))
        cache.put("a", value: "1")
        cache.put("b", value: "2")
        cache.put("c", value: "3")
        #expect(cache.size() == 2)
    }

    @Test func forgetsExpiredEntries() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.StepClock(current: 0, step: 100)
        let cache: Kit.Caching.TTLCache<String> = Kit.Caching.newTTLCache(8, ttl: 150, clock: clock)
        cache.put("key", value: "value")
        #expect(cache.purgeExpired() == 0)
        #expect(cache.purgeExpired() == 1)
    }
}
