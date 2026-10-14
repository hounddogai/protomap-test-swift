import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy program variances by code.
    protocol LegacyProgramVarianceStore {
        func find(_ code: String) -> LegacyProgramVariance?
        func save(_ item: LegacyProgramVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyProgramVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyProgramVarianceStore: LegacyProgramVarianceStore {
        var items: [String: LegacyProgramVariance]
        var order: [String]

        init(items: [String: LegacyProgramVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyProgramVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyProgramVariance) {
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

        func list() -> [LegacyProgramVariance] {
            var out: [LegacyProgramVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyProgramVarianceStore() -> any LegacyProgramVarianceStore {
        return MemoryLegacyProgramVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyProgramVarianceStore: LegacyProgramVarianceStore {
        var inner: MemoryLegacyProgramVarianceStore
        var cache: TTLCache<LegacyProgramVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyProgramVarianceStore, cache: TTLCache<LegacyProgramVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyProgramVariance? {
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

        func save(_ item: LegacyProgramVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyProgramVariance] {
            return inner.list()
        }
    }

    static func newCachedLegacyProgramVarianceStore(_ inner: MemoryLegacyProgramVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyProgramVarianceStore {
        return CachedLegacyProgramVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy program variances. Empty fields match all.
    final class LegacyProgramVarianceQuery {
        var locale: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minWeight: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyProgramVariance) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyProgramVariance]) -> [LegacyProgramVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyProgramVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyProgramVariances(_ store: any LegacyProgramVarianceStore, query: LegacyProgramVarianceQuery) -> [LegacyProgramVariance] {
        return query.apply(store.list())
    }
}
