import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled care protocol digests by code.
    protocol ScheduledCareProtocolDigestStore {
        func find(_ code: String) -> ScheduledCareProtocolDigest?
        func save(_ item: ScheduledCareProtocolDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolDigestStore: ScheduledCareProtocolDigestStore {
        var items: [String: ScheduledCareProtocolDigest]
        var order: [String]

        init(items: [String: ScheduledCareProtocolDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolDigest) {
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

        func list() -> [ScheduledCareProtocolDigest] {
            var out: [ScheduledCareProtocolDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolDigestStore() -> any ScheduledCareProtocolDigestStore {
        return MemoryScheduledCareProtocolDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolDigestStore: ScheduledCareProtocolDigestStore {
        var inner: MemoryScheduledCareProtocolDigestStore
        var cache: TTLCache<ScheduledCareProtocolDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolDigestStore, cache: TTLCache<ScheduledCareProtocolDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolDigest? {
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

        func save(_ item: ScheduledCareProtocolDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolDigest] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolDigestStore(_ inner: MemoryScheduledCareProtocolDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolDigestStore {
        return CachedScheduledCareProtocolDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol digests. Empty fields match all.
    final class ScheduledCareProtocolDigestQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ScheduledCareProtocolDigest]) -> [ScheduledCareProtocolDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolDigests(_ store: any ScheduledCareProtocolDigestStore, query: ScheduledCareProtocolDigestQuery) -> [ScheduledCareProtocolDigest] {
        return query.apply(store.list())
    }
}
