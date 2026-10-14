import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge variances by code.
    protocol ChargeVarianceStore {
        func find(_ code: String) -> ChargeVariance?
        func save(_ item: ChargeVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeVarianceStore: ChargeVarianceStore {
        var items: [String: ChargeVariance]
        var order: [String]

        init(items: [String: ChargeVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeVariance) {
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

        func list() -> [ChargeVariance] {
            var out: [ChargeVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeVarianceStore() -> any ChargeVarianceStore {
        return MemoryChargeVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeVarianceStore: ChargeVarianceStore {
        var inner: MemoryChargeVarianceStore
        var cache: TTLCache<ChargeVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeVarianceStore, cache: TTLCache<ChargeVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeVariance? {
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

        func save(_ item: ChargeVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeVariance] {
            return inner.list()
        }
    }

    static func newCachedChargeVarianceStore(_ inner: MemoryChargeVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeVarianceStore {
        return CachedChargeVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge variances. Empty fields match all.
    final class ChargeVarianceQuery {
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

        func matches(_ item: ChargeVariance) -> Bool {
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

        func apply(_ items: [ChargeVariance]) -> [ChargeVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeVariances(_ store: any ChargeVarianceStore, query: ChargeVarianceQuery) -> [ChargeVariance] {
        return query.apply(store.list())
    }
}
