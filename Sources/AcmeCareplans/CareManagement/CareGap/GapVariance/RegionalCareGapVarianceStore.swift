import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional care gap variances by code.
    protocol RegionalCareGapVarianceStore {
        func find(_ code: String) -> RegionalCareGapVariance?
        func save(_ item: RegionalCareGapVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCareGapVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCareGapVarianceStore: RegionalCareGapVarianceStore {
        var items: [String: RegionalCareGapVariance]
        var order: [String]

        init(items: [String: RegionalCareGapVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCareGapVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCareGapVariance) {
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

        func list() -> [RegionalCareGapVariance] {
            var out: [RegionalCareGapVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCareGapVarianceStore() -> any RegionalCareGapVarianceStore {
        return MemoryRegionalCareGapVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCareGapVarianceStore: RegionalCareGapVarianceStore {
        var inner: MemoryRegionalCareGapVarianceStore
        var cache: TTLCache<RegionalCareGapVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCareGapVarianceStore, cache: TTLCache<RegionalCareGapVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCareGapVariance? {
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

        func save(_ item: RegionalCareGapVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCareGapVariance] {
            return inner.list()
        }
    }

    static func newCachedRegionalCareGapVarianceStore(_ inner: MemoryRegionalCareGapVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCareGapVarianceStore {
        return CachedRegionalCareGapVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional care gap variances. Empty fields match all.
    final class RegionalCareGapVarianceQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCareGapVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCareGapVariance]) -> [RegionalCareGapVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCareGapVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCareGapVariances(_ store: any RegionalCareGapVarianceStore, query: RegionalCareGapVarianceQuery) -> [RegionalCareGapVariance] {
        return query.apply(store.list())
    }
}
