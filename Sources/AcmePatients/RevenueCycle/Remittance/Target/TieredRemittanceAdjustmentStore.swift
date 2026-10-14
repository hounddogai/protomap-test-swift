import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance adjustments by code.
    protocol TieredRemittanceAdjustmentStore {
        func find(_ code: String) -> TieredRemittanceAdjustment?
        func save(_ item: TieredRemittanceAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceAdjustmentStore: TieredRemittanceAdjustmentStore {
        var items: [String: TieredRemittanceAdjustment]
        var order: [String]

        init(items: [String: TieredRemittanceAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceAdjustment) {
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

        func list() -> [TieredRemittanceAdjustment] {
            var out: [TieredRemittanceAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceAdjustmentStore() -> any TieredRemittanceAdjustmentStore {
        return MemoryTieredRemittanceAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceAdjustmentStore: TieredRemittanceAdjustmentStore {
        var inner: MemoryTieredRemittanceAdjustmentStore
        var cache: TTLCache<TieredRemittanceAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceAdjustmentStore, cache: TTLCache<TieredRemittanceAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceAdjustment? {
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

        func save(_ item: TieredRemittanceAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceAdjustmentStore(_ inner: MemoryTieredRemittanceAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceAdjustmentStore {
        return CachedTieredRemittanceAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance adjustments. Empty fields match all.
    final class TieredRemittanceAdjustmentQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredRemittanceAdjustment]) -> [TieredRemittanceAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceAdjustments(_ store: any TieredRemittanceAdjustmentStore, query: TieredRemittanceAdjustmentQuery) -> [TieredRemittanceAdjustment] {
        return query.apply(store.list())
    }
}
