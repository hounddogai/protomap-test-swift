import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled care protocol profiles by code.
    protocol ScheduledCareProtocolProfileStore {
        func find(_ code: String) -> ScheduledCareProtocolProfile?
        func save(_ item: ScheduledCareProtocolProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolProfileStore: ScheduledCareProtocolProfileStore {
        var items: [String: ScheduledCareProtocolProfile]
        var order: [String]

        init(items: [String: ScheduledCareProtocolProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolProfile) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [ScheduledCareProtocolProfile] {
            var out: [ScheduledCareProtocolProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolProfileStore() -> any ScheduledCareProtocolProfileStore {
        return MemoryScheduledCareProtocolProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolProfileStore: ScheduledCareProtocolProfileStore {
        var inner: MemoryScheduledCareProtocolProfileStore
        var cache: TTLCache<ScheduledCareProtocolProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolProfileStore, cache: TTLCache<ScheduledCareProtocolProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolProfile? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: ScheduledCareProtocolProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolProfile] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolProfileStore(_ inner: MemoryScheduledCareProtocolProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolProfileStore {
        return CachedScheduledCareProtocolProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol profiles. Empty fields match all.
    final class ScheduledCareProtocolProfileQuery {
        var region: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRate: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolProfile) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCareProtocolProfile]) -> [ScheduledCareProtocolProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolProfiles(_ store: any ScheduledCareProtocolProfileStore, query: ScheduledCareProtocolProfileQuery) -> [ScheduledCareProtocolProfile] {
        return query.apply(store.list())
    }
}
