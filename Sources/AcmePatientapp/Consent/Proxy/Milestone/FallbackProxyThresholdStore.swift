import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback proxy thresholds by code.
    protocol FallbackProxyThresholdStore {
        func find(_ code: String) -> FallbackProxyThreshold?
        func save(_ item: FallbackProxyThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackProxyThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackProxyThresholdStore: FallbackProxyThresholdStore {
        var items: [String: FallbackProxyThreshold]
        var order: [String]

        init(items: [String: FallbackProxyThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackProxyThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackProxyThreshold) {
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

        func list() -> [FallbackProxyThreshold] {
            var out: [FallbackProxyThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackProxyThresholdStore() -> any FallbackProxyThresholdStore {
        return MemoryFallbackProxyThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackProxyThresholdStore: FallbackProxyThresholdStore {
        var inner: MemoryFallbackProxyThresholdStore
        var cache: TTLCache<FallbackProxyThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackProxyThresholdStore, cache: TTLCache<FallbackProxyThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackProxyThreshold? {
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

        func save(_ item: FallbackProxyThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackProxyThreshold] {
            return inner.list()
        }
    }

    static func newCachedFallbackProxyThresholdStore(_ inner: MemoryFallbackProxyThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackProxyThresholdStore {
        return CachedFallbackProxyThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback proxy thresholds. Empty fields match all.
    final class FallbackProxyThresholdQuery {
        var facility: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minLimit: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackProxyThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [FallbackProxyThreshold]) -> [FallbackProxyThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackProxyThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackProxyThresholds(_ store: any FallbackProxyThresholdStore, query: FallbackProxyThresholdQuery) -> [FallbackProxyThreshold] {
        return query.apply(store.list())
    }
}
