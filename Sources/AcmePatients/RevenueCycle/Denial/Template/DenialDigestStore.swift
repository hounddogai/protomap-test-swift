import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial digests by code.
    protocol DenialDigestStore {
        func find(_ code: String) -> DenialDigest?
        func save(_ item: DenialDigest)
        func remove(_ code: String) -> Bool
        func list() -> [DenialDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialDigestStore: DenialDigestStore {
        var items: [String: DenialDigest]
        var order: [String]

        init(items: [String: DenialDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialDigest) {
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

        func list() -> [DenialDigest] {
            var out: [DenialDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialDigestStore() -> any DenialDigestStore {
        return MemoryDenialDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialDigestStore: DenialDigestStore {
        var inner: MemoryDenialDigestStore
        var cache: TTLCache<DenialDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialDigestStore, cache: TTLCache<DenialDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialDigest? {
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

        func save(_ item: DenialDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialDigest] {
            return inner.list()
        }
    }

    static func newCachedDenialDigestStore(_ inner: MemoryDenialDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialDigestStore {
        return CachedDenialDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial digests. Empty fields match all.
    final class DenialDigestQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DenialDigest]) -> [DenialDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialDigests(_ store: any DenialDigestStore, query: DenialDigestQuery) -> [DenialDigest] {
        return query.apply(store.list())
    }
}
