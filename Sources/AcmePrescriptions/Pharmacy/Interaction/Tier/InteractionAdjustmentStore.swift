import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction adjustments by code.
    protocol InteractionAdjustmentStore {
        func find(_ code: String) -> InteractionAdjustment?
        func save(_ item: InteractionAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionAdjustmentStore: InteractionAdjustmentStore {
        var items: [String: InteractionAdjustment]
        var order: [String]

        init(items: [String: InteractionAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionAdjustment) {
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

        func list() -> [InteractionAdjustment] {
            var out: [InteractionAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionAdjustmentStore() -> any InteractionAdjustmentStore {
        return MemoryInteractionAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionAdjustmentStore: InteractionAdjustmentStore {
        var inner: MemoryInteractionAdjustmentStore
        var cache: TTLCache<InteractionAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionAdjustmentStore, cache: TTLCache<InteractionAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionAdjustment? {
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

        func save(_ item: InteractionAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionAdjustment] {
            return inner.list()
        }
    }

    static func newCachedInteractionAdjustmentStore(_ inner: MemoryInteractionAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionAdjustmentStore {
        return CachedInteractionAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction adjustments. Empty fields match all.
    final class InteractionAdjustmentQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionAdjustment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [InteractionAdjustment]) -> [InteractionAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionAdjustments(_ store: any InteractionAdjustmentStore, query: InteractionAdjustmentQuery) -> [InteractionAdjustment] {
        return query.apply(store.list())
    }
}
