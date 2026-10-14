import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff adjustments by code.
    protocol HandoffAdjustmentStore {
        func find(_ code: String) -> HandoffAdjustment?
        func save(_ item: HandoffAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffAdjustmentStore: HandoffAdjustmentStore {
        var items: [String: HandoffAdjustment]
        var order: [String]

        init(items: [String: HandoffAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffAdjustment) {
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

        func list() -> [HandoffAdjustment] {
            var out: [HandoffAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffAdjustmentStore() -> any HandoffAdjustmentStore {
        return MemoryHandoffAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffAdjustmentStore: HandoffAdjustmentStore {
        var inner: MemoryHandoffAdjustmentStore
        var cache: TTLCache<HandoffAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffAdjustmentStore, cache: TTLCache<HandoffAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffAdjustment? {
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

        func save(_ item: HandoffAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffAdjustment] {
            return inner.list()
        }
    }

    static func newCachedHandoffAdjustmentStore(_ inner: MemoryHandoffAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffAdjustmentStore {
        return CachedHandoffAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff adjustments. Empty fields match all.
    final class HandoffAdjustmentQuery {
        var ward: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffAdjustment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffAdjustment]) -> [HandoffAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffAdjustments(_ store: any HandoffAdjustmentStore, query: HandoffAdjustmentQuery) -> [HandoffAdjustment] {
        return query.apply(store.list())
    }
}
