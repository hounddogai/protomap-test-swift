import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient witness variances by code.
    protocol LenientWitnessVarianceStore {
        func find(_ code: String) -> LenientWitnessVariance?
        func save(_ item: LenientWitnessVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientWitnessVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientWitnessVarianceStore: LenientWitnessVarianceStore {
        var items: [String: LenientWitnessVariance]
        var order: [String]

        init(items: [String: LenientWitnessVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientWitnessVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientWitnessVariance) {
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

        func list() -> [LenientWitnessVariance] {
            var out: [LenientWitnessVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientWitnessVarianceStore() -> any LenientWitnessVarianceStore {
        return MemoryLenientWitnessVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientWitnessVarianceStore: LenientWitnessVarianceStore {
        var inner: MemoryLenientWitnessVarianceStore
        var cache: TTLCache<LenientWitnessVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientWitnessVarianceStore, cache: TTLCache<LenientWitnessVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientWitnessVariance? {
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

        func save(_ item: LenientWitnessVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientWitnessVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientWitnessVarianceStore(_ inner: MemoryLenientWitnessVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientWitnessVarianceStore {
        return CachedLenientWitnessVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient witness variances. Empty fields match all.
    final class LenientWitnessVarianceQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientWitnessVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientWitnessVariance]) -> [LenientWitnessVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientWitnessVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientWitnessVariances(_ store: any LenientWitnessVarianceStore, query: LenientWitnessVarianceQuery) -> [LenientWitnessVariance] {
        return query.apply(store.list())
    }
}
