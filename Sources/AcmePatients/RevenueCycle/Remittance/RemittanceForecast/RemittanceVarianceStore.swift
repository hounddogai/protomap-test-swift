import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance variances by code.
    protocol RemittanceVarianceStore {
        func find(_ code: String) -> RemittanceVariance?
        func save(_ item: RemittanceVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceVarianceStore: RemittanceVarianceStore {
        var items: [String: RemittanceVariance]
        var order: [String]

        init(items: [String: RemittanceVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceVariance) {
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

        func list() -> [RemittanceVariance] {
            var out: [RemittanceVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceVarianceStore() -> any RemittanceVarianceStore {
        return MemoryRemittanceVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceVarianceStore: RemittanceVarianceStore {
        var inner: MemoryRemittanceVarianceStore
        var cache: TTLCache<RemittanceVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceVarianceStore, cache: TTLCache<RemittanceVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceVariance? {
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

        func save(_ item: RemittanceVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceVariance] {
            return inner.list()
        }
    }

    static func newCachedRemittanceVarianceStore(_ inner: MemoryRemittanceVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceVarianceStore {
        return CachedRemittanceVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance variances. Empty fields match all.
    final class RemittanceVarianceQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceVariance]) -> [RemittanceVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceVariances(_ store: any RemittanceVarianceStore, query: RemittanceVarianceQuery) -> [RemittanceVariance] {
        return query.apply(store.list())
    }
}
