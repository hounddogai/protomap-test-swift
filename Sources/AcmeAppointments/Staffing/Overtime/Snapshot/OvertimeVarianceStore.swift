import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime variances by code.
    protocol OvertimeVarianceStore {
        func find(_ code: String) -> OvertimeVariance?
        func save(_ item: OvertimeVariance)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeVarianceStore: OvertimeVarianceStore {
        var items: [String: OvertimeVariance]
        var order: [String]

        init(items: [String: OvertimeVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeVariance) {
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

        func list() -> [OvertimeVariance] {
            var out: [OvertimeVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeVarianceStore() -> any OvertimeVarianceStore {
        return MemoryOvertimeVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeVarianceStore: OvertimeVarianceStore {
        var inner: MemoryOvertimeVarianceStore
        var cache: TTLCache<OvertimeVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeVarianceStore, cache: TTLCache<OvertimeVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeVariance? {
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

        func save(_ item: OvertimeVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeVariance] {
            return inner.list()
        }
    }

    static func newCachedOvertimeVarianceStore(_ inner: MemoryOvertimeVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeVarianceStore {
        return CachedOvertimeVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime variances. Empty fields match all.
    final class OvertimeVarianceQuery {
        var region: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeVariance]) -> [OvertimeVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeVariances(_ store: any OvertimeVarianceStore, query: OvertimeVarianceQuery) -> [OvertimeVariance] {
        return query.apply(store.list())
    }
}
