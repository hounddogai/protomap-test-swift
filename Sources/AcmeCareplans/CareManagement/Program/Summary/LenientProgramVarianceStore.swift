import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient program variances by code.
    protocol LenientProgramVarianceStore {
        func find(_ code: String) -> LenientProgramVariance?
        func save(_ item: LenientProgramVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProgramVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProgramVarianceStore: LenientProgramVarianceStore {
        var items: [String: LenientProgramVariance]
        var order: [String]

        init(items: [String: LenientProgramVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProgramVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProgramVariance) {
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

        func list() -> [LenientProgramVariance] {
            var out: [LenientProgramVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProgramVarianceStore() -> any LenientProgramVarianceStore {
        return MemoryLenientProgramVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProgramVarianceStore: LenientProgramVarianceStore {
        var inner: MemoryLenientProgramVarianceStore
        var cache: TTLCache<LenientProgramVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProgramVarianceStore, cache: TTLCache<LenientProgramVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProgramVariance? {
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

        func save(_ item: LenientProgramVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProgramVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientProgramVarianceStore(_ inner: MemoryLenientProgramVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProgramVarianceStore {
        return CachedLenientProgramVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient program variances. Empty fields match all.
    final class LenientProgramVarianceQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProgramVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [LenientProgramVariance]) -> [LenientProgramVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProgramVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProgramVariances(_ store: any LenientProgramVarianceStore, query: LenientProgramVarianceQuery) -> [LenientProgramVariance] {
        return query.apply(store.list())
    }
}
