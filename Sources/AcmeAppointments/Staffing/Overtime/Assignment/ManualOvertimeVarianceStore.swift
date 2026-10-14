import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual overtime variances by code.
    protocol ManualOvertimeVarianceStore {
        func find(_ code: String) -> ManualOvertimeVariance?
        func save(_ item: ManualOvertimeVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOvertimeVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOvertimeVarianceStore: ManualOvertimeVarianceStore {
        var items: [String: ManualOvertimeVariance]
        var order: [String]

        init(items: [String: ManualOvertimeVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOvertimeVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOvertimeVariance) {
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

        func list() -> [ManualOvertimeVariance] {
            var out: [ManualOvertimeVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOvertimeVarianceStore() -> any ManualOvertimeVarianceStore {
        return MemoryManualOvertimeVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOvertimeVarianceStore: ManualOvertimeVarianceStore {
        var inner: MemoryManualOvertimeVarianceStore
        var cache: TTLCache<ManualOvertimeVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOvertimeVarianceStore, cache: TTLCache<ManualOvertimeVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOvertimeVariance? {
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

        func save(_ item: ManualOvertimeVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOvertimeVariance] {
            return inner.list()
        }
    }

    static func newCachedManualOvertimeVarianceStore(_ inner: MemoryManualOvertimeVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOvertimeVarianceStore {
        return CachedManualOvertimeVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual overtime variances. Empty fields match all.
    final class ManualOvertimeVarianceQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOvertimeVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualOvertimeVariance]) -> [ManualOvertimeVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOvertimeVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOvertimeVariances(_ store: any ManualOvertimeVarianceStore, query: ManualOvertimeVarianceQuery) -> [ManualOvertimeVariance] {
        return query.apply(store.list())
    }
}
