import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual remittance adjustments by code.
    protocol ManualRemittanceAdjustmentStore {
        func find(_ code: String) -> ManualRemittanceAdjustment?
        func save(_ item: ManualRemittanceAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRemittanceAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRemittanceAdjustmentStore: ManualRemittanceAdjustmentStore {
        var items: [String: ManualRemittanceAdjustment]
        var order: [String]

        init(items: [String: ManualRemittanceAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRemittanceAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRemittanceAdjustment) {
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

        func list() -> [ManualRemittanceAdjustment] {
            var out: [ManualRemittanceAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRemittanceAdjustmentStore() -> any ManualRemittanceAdjustmentStore {
        return MemoryManualRemittanceAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRemittanceAdjustmentStore: ManualRemittanceAdjustmentStore {
        var inner: MemoryManualRemittanceAdjustmentStore
        var cache: TTLCache<ManualRemittanceAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRemittanceAdjustmentStore, cache: TTLCache<ManualRemittanceAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRemittanceAdjustment? {
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

        func save(_ item: ManualRemittanceAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRemittanceAdjustment] {
            return inner.list()
        }
    }

    static func newCachedManualRemittanceAdjustmentStore(_ inner: MemoryManualRemittanceAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRemittanceAdjustmentStore {
        return CachedManualRemittanceAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual remittance adjustments. Empty fields match all.
    final class ManualRemittanceAdjustmentQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRemittanceAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ManualRemittanceAdjustment]) -> [ManualRemittanceAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRemittanceAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRemittanceAdjustments(_ store: any ManualRemittanceAdjustmentStore, query: ManualRemittanceAdjustmentQuery) -> [ManualRemittanceAdjustment] {
        return query.apply(store.list())
    }
}
