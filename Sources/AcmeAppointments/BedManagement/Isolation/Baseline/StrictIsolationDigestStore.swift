import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict isolation digests by code.
    protocol StrictIsolationDigestStore {
        func find(_ code: String) -> StrictIsolationDigest?
        func save(_ item: StrictIsolationDigest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictIsolationDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictIsolationDigestStore: StrictIsolationDigestStore {
        var items: [String: StrictIsolationDigest]
        var order: [String]

        init(items: [String: StrictIsolationDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictIsolationDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictIsolationDigest) {
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

        func list() -> [StrictIsolationDigest] {
            var out: [StrictIsolationDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictIsolationDigestStore() -> any StrictIsolationDigestStore {
        return MemoryStrictIsolationDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictIsolationDigestStore: StrictIsolationDigestStore {
        var inner: MemoryStrictIsolationDigestStore
        var cache: TTLCache<StrictIsolationDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictIsolationDigestStore, cache: TTLCache<StrictIsolationDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictIsolationDigest? {
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

        func save(_ item: StrictIsolationDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictIsolationDigest] {
            return inner.list()
        }
    }

    static func newCachedStrictIsolationDigestStore(_ inner: MemoryStrictIsolationDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictIsolationDigestStore {
        return CachedStrictIsolationDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict isolation digests. Empty fields match all.
    final class StrictIsolationDigestQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictIsolationDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictIsolationDigest]) -> [StrictIsolationDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictIsolationDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictIsolationDigests(_ store: any StrictIsolationDigestStore, query: StrictIsolationDigestQuery) -> [StrictIsolationDigest] {
        return query.apply(store.list())
    }
}
