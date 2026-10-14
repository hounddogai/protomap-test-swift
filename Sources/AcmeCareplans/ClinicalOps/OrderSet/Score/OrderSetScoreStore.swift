import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set scores by code.
    protocol OrderSetScoreStore {
        func find(_ code: String) -> OrderSetScore?
        func save(_ item: OrderSetScore)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetScoreStore: OrderSetScoreStore {
        var items: [String: OrderSetScore]
        var order: [String]

        init(items: [String: OrderSetScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetScore) {
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

        func list() -> [OrderSetScore] {
            var out: [OrderSetScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetScoreStore() -> any OrderSetScoreStore {
        return MemoryOrderSetScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetScoreStore: OrderSetScoreStore {
        var inner: MemoryOrderSetScoreStore
        var cache: TTLCache<OrderSetScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetScoreStore, cache: TTLCache<OrderSetScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetScore? {
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

        func save(_ item: OrderSetScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetScore] {
            return inner.list()
        }
    }

    static func newCachedOrderSetScoreStore(_ inner: MemoryOrderSetScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetScoreStore {
        return CachedOrderSetScoreStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set scores. Empty fields match all.
    final class OrderSetScoreQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetScore]) -> [OrderSetScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetScores(_ store: any OrderSetScoreStore, query: OrderSetScoreQuery) -> [OrderSetScore] {
        return query.apply(store.list())
    }
}
