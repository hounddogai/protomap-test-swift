import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census cycles by code.
    protocol CensusCycleStore {
        func find(_ code: String) -> CensusCycle?
        func save(_ item: CensusCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CensusCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusCycleStore: CensusCycleStore {
        var items: [String: CensusCycle]
        var order: [String]

        init(items: [String: CensusCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusCycle) {
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

        func list() -> [CensusCycle] {
            var out: [CensusCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusCycleStore() -> any CensusCycleStore {
        return MemoryCensusCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusCycleStore: CensusCycleStore {
        var inner: MemoryCensusCycleStore
        var cache: TTLCache<CensusCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusCycleStore, cache: TTLCache<CensusCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusCycle? {
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

        func save(_ item: CensusCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusCycle] {
            return inner.list()
        }
    }

    static func newCachedCensusCycleStore(_ inner: MemoryCensusCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusCycleStore {
        return CachedCensusCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census cycles. Empty fields match all.
    final class CensusCycleQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusCycle]) -> [CensusCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusCycles(_ store: any CensusCycleStore, query: CensusCycleQuery) -> [CensusCycle] {
        return query.apply(store.list())
    }
}
