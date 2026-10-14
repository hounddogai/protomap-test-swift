import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback interaction digests by code.
    protocol FallbackInteractionDigestStore {
        func find(_ code: String) -> FallbackInteractionDigest?
        func save(_ item: FallbackInteractionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackInteractionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackInteractionDigestStore: FallbackInteractionDigestStore {
        var items: [String: FallbackInteractionDigest]
        var order: [String]

        init(items: [String: FallbackInteractionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackInteractionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackInteractionDigest) {
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

        func list() -> [FallbackInteractionDigest] {
            var out: [FallbackInteractionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackInteractionDigestStore() -> any FallbackInteractionDigestStore {
        return MemoryFallbackInteractionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackInteractionDigestStore: FallbackInteractionDigestStore {
        var inner: MemoryFallbackInteractionDigestStore
        var cache: TTLCache<FallbackInteractionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackInteractionDigestStore, cache: TTLCache<FallbackInteractionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackInteractionDigest? {
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

        func save(_ item: FallbackInteractionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackInteractionDigest] {
            return inner.list()
        }
    }

    static func newCachedFallbackInteractionDigestStore(_ inner: MemoryFallbackInteractionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackInteractionDigestStore {
        return CachedFallbackInteractionDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback interaction digests. Empty fields match all.
    final class FallbackInteractionDigestQuery {
        var unit: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minLimit: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackInteractionDigest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackInteractionDigest]) -> [FallbackInteractionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackInteractionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackInteractionDigests(_ store: any FallbackInteractionDigestStore, query: FallbackInteractionDigestQuery) -> [FallbackInteractionDigest] {
        return query.apply(store.list())
    }
}
