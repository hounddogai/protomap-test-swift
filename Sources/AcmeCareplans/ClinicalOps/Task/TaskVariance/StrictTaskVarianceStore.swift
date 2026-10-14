import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict task variances by code.
    protocol StrictTaskVarianceStore {
        func find(_ code: String) -> StrictTaskVariance?
        func save(_ item: StrictTaskVariance)
        func remove(_ code: String) -> Bool
        func list() -> [StrictTaskVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictTaskVarianceStore: StrictTaskVarianceStore {
        var items: [String: StrictTaskVariance]
        var order: [String]

        init(items: [String: StrictTaskVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictTaskVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictTaskVariance) {
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

        func list() -> [StrictTaskVariance] {
            var out: [StrictTaskVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictTaskVarianceStore() -> any StrictTaskVarianceStore {
        return MemoryStrictTaskVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictTaskVarianceStore: StrictTaskVarianceStore {
        var inner: MemoryStrictTaskVarianceStore
        var cache: TTLCache<StrictTaskVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictTaskVarianceStore, cache: TTLCache<StrictTaskVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictTaskVariance? {
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

        func save(_ item: StrictTaskVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictTaskVariance] {
            return inner.list()
        }
    }

    static func newCachedStrictTaskVarianceStore(_ inner: MemoryStrictTaskVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictTaskVarianceStore {
        return CachedStrictTaskVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict task variances. Empty fields match all.
    final class StrictTaskVarianceQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictTaskVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictTaskVariance]) -> [StrictTaskVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictTaskVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictTaskVariances(_ store: any StrictTaskVarianceStore, query: StrictTaskVarianceQuery) -> [StrictTaskVariance] {
        return query.apply(store.list())
    }
}
