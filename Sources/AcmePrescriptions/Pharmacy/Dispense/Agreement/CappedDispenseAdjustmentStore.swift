import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped dispense adjustments by code.
    protocol CappedDispenseAdjustmentStore {
        func find(_ code: String) -> CappedDispenseAdjustment?
        func save(_ item: CappedDispenseAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDispenseAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDispenseAdjustmentStore: CappedDispenseAdjustmentStore {
        var items: [String: CappedDispenseAdjustment]
        var order: [String]

        init(items: [String: CappedDispenseAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDispenseAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDispenseAdjustment) {
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

        func list() -> [CappedDispenseAdjustment] {
            var out: [CappedDispenseAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDispenseAdjustmentStore() -> any CappedDispenseAdjustmentStore {
        return MemoryCappedDispenseAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDispenseAdjustmentStore: CappedDispenseAdjustmentStore {
        var inner: MemoryCappedDispenseAdjustmentStore
        var cache: TTLCache<CappedDispenseAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDispenseAdjustmentStore, cache: TTLCache<CappedDispenseAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDispenseAdjustment? {
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

        func save(_ item: CappedDispenseAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDispenseAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCappedDispenseAdjustmentStore(_ inner: MemoryCappedDispenseAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDispenseAdjustmentStore {
        return CachedCappedDispenseAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped dispense adjustments. Empty fields match all.
    final class CappedDispenseAdjustmentQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDispenseAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDispenseAdjustment]) -> [CappedDispenseAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDispenseAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDispenseAdjustments(_ store: any CappedDispenseAdjustmentStore, query: CappedDispenseAdjustmentQuery) -> [CappedDispenseAdjustment] {
        return query.apply(store.list())
    }
}
