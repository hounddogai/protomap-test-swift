import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual discharge plan variances by code.
    protocol ManualDischargePlanVarianceStore {
        func find(_ code: String) -> ManualDischargePlanVariance?
        func save(_ item: ManualDischargePlanVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDischargePlanVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDischargePlanVarianceStore: ManualDischargePlanVarianceStore {
        var items: [String: ManualDischargePlanVariance]
        var order: [String]

        init(items: [String: ManualDischargePlanVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDischargePlanVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDischargePlanVariance) {
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

        func list() -> [ManualDischargePlanVariance] {
            var out: [ManualDischargePlanVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDischargePlanVarianceStore() -> any ManualDischargePlanVarianceStore {
        return MemoryManualDischargePlanVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDischargePlanVarianceStore: ManualDischargePlanVarianceStore {
        var inner: MemoryManualDischargePlanVarianceStore
        var cache: TTLCache<ManualDischargePlanVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDischargePlanVarianceStore, cache: TTLCache<ManualDischargePlanVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDischargePlanVariance? {
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

        func save(_ item: ManualDischargePlanVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDischargePlanVariance] {
            return inner.list()
        }
    }

    static func newCachedManualDischargePlanVarianceStore(_ inner: MemoryManualDischargePlanVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDischargePlanVarianceStore {
        return CachedManualDischargePlanVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual discharge plan variances. Empty fields match all.
    final class ManualDischargePlanVarianceQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDischargePlanVariance) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualDischargePlanVariance]) -> [ManualDischargePlanVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDischargePlanVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDischargePlanVariances(_ store: any ManualDischargePlanVarianceStore, query: ManualDischargePlanVarianceQuery) -> [ManualDischargePlanVariance] {
        return query.apply(store.list())
    }
}
