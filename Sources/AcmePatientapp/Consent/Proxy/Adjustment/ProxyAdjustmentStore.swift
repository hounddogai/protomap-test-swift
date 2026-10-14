import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy adjustments by code.
    protocol ProxyAdjustmentStore {
        func find(_ code: String) -> ProxyAdjustment?
        func save(_ item: ProxyAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyAdjustmentStore: ProxyAdjustmentStore {
        var items: [String: ProxyAdjustment]
        var order: [String]

        init(items: [String: ProxyAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyAdjustment) {
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

        func list() -> [ProxyAdjustment] {
            var out: [ProxyAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyAdjustmentStore() -> any ProxyAdjustmentStore {
        return MemoryProxyAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyAdjustmentStore: ProxyAdjustmentStore {
        var inner: MemoryProxyAdjustmentStore
        var cache: TTLCache<ProxyAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyAdjustmentStore, cache: TTLCache<ProxyAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyAdjustment? {
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

        func save(_ item: ProxyAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyAdjustment] {
            return inner.list()
        }
    }

    static func newCachedProxyAdjustmentStore(_ inner: MemoryProxyAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyAdjustmentStore {
        return CachedProxyAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy adjustments. Empty fields match all.
    final class ProxyAdjustmentQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyAdjustment]) -> [ProxyAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyAdjustments(_ store: any ProxyAdjustmentStore, query: ProxyAdjustmentQuery) -> [ProxyAdjustment] {
        return query.apply(store.list())
    }
}
