import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global slot adjustments by code.
    protocol GlobalSlotAdjustmentStore {
        func find(_ code: String) -> GlobalSlotAdjustment?
        func save(_ item: GlobalSlotAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSlotAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSlotAdjustmentStore: GlobalSlotAdjustmentStore {
        var items: [String: GlobalSlotAdjustment]
        var order: [String]

        init(items: [String: GlobalSlotAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSlotAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSlotAdjustment) {
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

        func list() -> [GlobalSlotAdjustment] {
            var out: [GlobalSlotAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSlotAdjustmentStore() -> any GlobalSlotAdjustmentStore {
        return MemoryGlobalSlotAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSlotAdjustmentStore: GlobalSlotAdjustmentStore {
        var inner: MemoryGlobalSlotAdjustmentStore
        var cache: TTLCache<GlobalSlotAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSlotAdjustmentStore, cache: TTLCache<GlobalSlotAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSlotAdjustment? {
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

        func save(_ item: GlobalSlotAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSlotAdjustment] {
            return inner.list()
        }
    }

    static func newCachedGlobalSlotAdjustmentStore(_ inner: MemoryGlobalSlotAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSlotAdjustmentStore {
        return CachedGlobalSlotAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global slot adjustments. Empty fields match all.
    final class GlobalSlotAdjustmentQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSlotAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSlotAdjustment]) -> [GlobalSlotAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSlotAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSlotAdjustments(_ store: any GlobalSlotAdjustmentStore, query: GlobalSlotAdjustmentQuery) -> [GlobalSlotAdjustment] {
        return query.apply(store.list())
    }
}
