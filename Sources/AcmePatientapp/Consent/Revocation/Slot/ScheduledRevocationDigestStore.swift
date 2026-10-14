import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation digests by code.
    protocol ScheduledRevocationDigestStore {
        func find(_ code: String) -> ScheduledRevocationDigest?
        func save(_ item: ScheduledRevocationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationDigestStore: ScheduledRevocationDigestStore {
        var items: [String: ScheduledRevocationDigest]
        var order: [String]

        init(items: [String: ScheduledRevocationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationDigest) {
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

        func list() -> [ScheduledRevocationDigest] {
            var out: [ScheduledRevocationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationDigestStore() -> any ScheduledRevocationDigestStore {
        return MemoryScheduledRevocationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationDigestStore: ScheduledRevocationDigestStore {
        var inner: MemoryScheduledRevocationDigestStore
        var cache: TTLCache<ScheduledRevocationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationDigestStore, cache: TTLCache<ScheduledRevocationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationDigest? {
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

        func save(_ item: ScheduledRevocationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationDigest] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationDigestStore(_ inner: MemoryScheduledRevocationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationDigestStore {
        return CachedScheduledRevocationDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation digests. Empty fields match all.
    final class ScheduledRevocationDigestQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationDigest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledRevocationDigest]) -> [ScheduledRevocationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationDigests(_ store: any ScheduledRevocationDigestStore, query: ScheduledRevocationDigestQuery) -> [ScheduledRevocationDigest] {
        return query.apply(store.list())
    }
}
