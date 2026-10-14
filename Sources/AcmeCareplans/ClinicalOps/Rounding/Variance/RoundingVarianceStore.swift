import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding variances by code.
    protocol RoundingVarianceStore {
        func find(_ code: String) -> RoundingVariance?
        func save(_ item: RoundingVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingVarianceStore: RoundingVarianceStore {
        var items: [String: RoundingVariance]
        var order: [String]

        init(items: [String: RoundingVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingVariance) {
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

        func list() -> [RoundingVariance] {
            var out: [RoundingVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingVarianceStore() -> any RoundingVarianceStore {
        return MemoryRoundingVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingVarianceStore: RoundingVarianceStore {
        var inner: MemoryRoundingVarianceStore
        var cache: TTLCache<RoundingVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingVarianceStore, cache: TTLCache<RoundingVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingVariance? {
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

        func save(_ item: RoundingVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingVariance] {
            return inner.list()
        }
    }

    static func newCachedRoundingVarianceStore(_ inner: MemoryRoundingVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingVarianceStore {
        return CachedRoundingVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding variances. Empty fields match all.
    final class RoundingVarianceQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingVariance) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingVariance]) -> [RoundingVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingVariances(_ store: any RoundingVarianceStore, query: RoundingVarianceQuery) -> [RoundingVariance] {
        return query.apply(store.list())
    }
}
