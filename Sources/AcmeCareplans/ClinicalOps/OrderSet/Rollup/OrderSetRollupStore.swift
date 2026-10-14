import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set rollups by code.
    protocol OrderSetRollupStore {
        func find(_ code: String) -> OrderSetRollup?
        func save(_ item: OrderSetRollup)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetRollupStore: OrderSetRollupStore {
        var items: [String: OrderSetRollup]
        var order: [String]

        init(items: [String: OrderSetRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetRollup) {
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

        func list() -> [OrderSetRollup] {
            var out: [OrderSetRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetRollupStore() -> any OrderSetRollupStore {
        return MemoryOrderSetRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetRollupStore: OrderSetRollupStore {
        var inner: MemoryOrderSetRollupStore
        var cache: TTLCache<OrderSetRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetRollupStore, cache: TTLCache<OrderSetRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetRollup? {
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

        func save(_ item: OrderSetRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetRollup] {
            return inner.list()
        }
    }

    static func newCachedOrderSetRollupStore(_ inner: MemoryOrderSetRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetRollupStore {
        return CachedOrderSetRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set rollups. Empty fields match all.
    final class OrderSetRollupQuery {
        var source: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetRollup) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetRollup]) -> [OrderSetRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetRollups(_ store: any OrderSetRollupStore, query: OrderSetRollupQuery) -> [OrderSetRollup] {
        return query.apply(store.list())
    }
}
