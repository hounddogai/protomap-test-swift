import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure digests by code.
    protocol ClosureDigestStore {
        func find(_ code: String) -> ClosureDigest?
        func save(_ item: ClosureDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureDigestStore: ClosureDigestStore {
        var items: [String: ClosureDigest]
        var order: [String]

        init(items: [String: ClosureDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureDigest) {
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

        func list() -> [ClosureDigest] {
            var out: [ClosureDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureDigestStore() -> any ClosureDigestStore {
        return MemoryClosureDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureDigestStore: ClosureDigestStore {
        var inner: MemoryClosureDigestStore
        var cache: TTLCache<ClosureDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureDigestStore, cache: TTLCache<ClosureDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureDigest? {
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

        func save(_ item: ClosureDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureDigest] {
            return inner.list()
        }
    }

    static func newCachedClosureDigestStore(_ inner: MemoryClosureDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureDigestStore {
        return CachedClosureDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure digests. Empty fields match all.
    final class ClosureDigestQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureDigest]) -> [ClosureDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureDigests(_ store: any ClosureDigestStore, query: ClosureDigestQuery) -> [ClosureDigest] {
        return query.apply(store.list())
    }
}
