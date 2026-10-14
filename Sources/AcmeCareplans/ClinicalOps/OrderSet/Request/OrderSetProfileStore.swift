import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set profiles by code.
    protocol OrderSetProfileStore {
        func find(_ code: String) -> OrderSetProfile?
        func save(_ item: OrderSetProfile)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetProfileStore: OrderSetProfileStore {
        var items: [String: OrderSetProfile]
        var order: [String]

        init(items: [String: OrderSetProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetProfile) {
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

        func list() -> [OrderSetProfile] {
            var out: [OrderSetProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetProfileStore() -> any OrderSetProfileStore {
        return MemoryOrderSetProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetProfileStore: OrderSetProfileStore {
        var inner: MemoryOrderSetProfileStore
        var cache: TTLCache<OrderSetProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetProfileStore, cache: TTLCache<OrderSetProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetProfile? {
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

        func save(_ item: OrderSetProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetProfile] {
            return inner.list()
        }
    }

    static func newCachedOrderSetProfileStore(_ inner: MemoryOrderSetProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetProfileStore {
        return CachedOrderSetProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set profiles. Empty fields match all.
    final class OrderSetProfileQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetProfile]) -> [OrderSetProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetProfiles(_ store: any OrderSetProfileStore, query: OrderSetProfileQuery) -> [OrderSetProfile] {
        return query.apply(store.list())
    }
}
