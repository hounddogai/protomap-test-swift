import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness cycles by code.
    protocol WitnessCycleStore {
        func find(_ code: String) -> WitnessCycle?
        func save(_ item: WitnessCycle)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessCycleStore: WitnessCycleStore {
        var items: [String: WitnessCycle]
        var order: [String]

        init(items: [String: WitnessCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessCycle) {
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

        func list() -> [WitnessCycle] {
            var out: [WitnessCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessCycleStore() -> any WitnessCycleStore {
        return MemoryWitnessCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessCycleStore: WitnessCycleStore {
        var inner: MemoryWitnessCycleStore
        var cache: TTLCache<WitnessCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessCycleStore, cache: TTLCache<WitnessCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessCycle? {
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

        func save(_ item: WitnessCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessCycle] {
            return inner.list()
        }
    }

    static func newCachedWitnessCycleStore(_ inner: MemoryWitnessCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessCycleStore {
        return CachedWitnessCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness cycles. Empty fields match all.
    final class WitnessCycleQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [WitnessCycle]) -> [WitnessCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessCycles(_ store: any WitnessCycleStore, query: WitnessCycleQuery) -> [WitnessCycle] {
        return query.apply(store.list())
    }
}
