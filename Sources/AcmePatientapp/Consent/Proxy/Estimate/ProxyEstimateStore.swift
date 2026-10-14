import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy estimates by code.
    protocol ProxyEstimateStore {
        func find(_ code: String) -> ProxyEstimate?
        func save(_ item: ProxyEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyEstimateStore: ProxyEstimateStore {
        var items: [String: ProxyEstimate]
        var order: [String]

        init(items: [String: ProxyEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyEstimate) {
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

        func list() -> [ProxyEstimate] {
            var out: [ProxyEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyEstimateStore() -> any ProxyEstimateStore {
        return MemoryProxyEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyEstimateStore: ProxyEstimateStore {
        var inner: MemoryProxyEstimateStore
        var cache: TTLCache<ProxyEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyEstimateStore, cache: TTLCache<ProxyEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyEstimate? {
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

        func save(_ item: ProxyEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyEstimate] {
            return inner.list()
        }
    }

    static func newCachedProxyEstimateStore(_ inner: MemoryProxyEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyEstimateStore {
        return CachedProxyEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy estimates. Empty fields match all.
    final class ProxyEstimateQuery {
        var region: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyEstimate) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ProxyEstimate]) -> [ProxyEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyEstimates(_ store: any ProxyEstimateStore, query: ProxyEstimateQuery) -> [ProxyEstimate] {
        return query.apply(store.list())
    }
}
