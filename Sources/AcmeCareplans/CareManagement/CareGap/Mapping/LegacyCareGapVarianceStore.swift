import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy care gap variances by code.
    protocol LegacyCareGapVarianceStore {
        func find(_ code: String) -> LegacyCareGapVariance?
        func save(_ item: LegacyCareGapVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCareGapVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCareGapVarianceStore: LegacyCareGapVarianceStore {
        var items: [String: LegacyCareGapVariance]
        var order: [String]

        init(items: [String: LegacyCareGapVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCareGapVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCareGapVariance) {
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

        func list() -> [LegacyCareGapVariance] {
            var out: [LegacyCareGapVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCareGapVarianceStore() -> any LegacyCareGapVarianceStore {
        return MemoryLegacyCareGapVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCareGapVarianceStore: LegacyCareGapVarianceStore {
        var inner: MemoryLegacyCareGapVarianceStore
        var cache: TTLCache<LegacyCareGapVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCareGapVarianceStore, cache: TTLCache<LegacyCareGapVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCareGapVariance? {
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

        func save(_ item: LegacyCareGapVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCareGapVariance] {
            return inner.list()
        }
    }

    static func newCachedLegacyCareGapVarianceStore(_ inner: MemoryLegacyCareGapVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCareGapVarianceStore {
        return CachedLegacyCareGapVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy care gap variances. Empty fields match all.
    final class LegacyCareGapVarianceQuery {
        var region: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCareGapVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCareGapVariance]) -> [LegacyCareGapVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCareGapVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCareGapVariances(_ store: any LegacyCareGapVarianceStore, query: LegacyCareGapVarianceQuery) -> [LegacyCareGapVariance] {
        return query.apply(store.list())
    }
}
