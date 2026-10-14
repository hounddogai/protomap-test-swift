import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier cycles by code.
    protocol CourierCycleStore {
        func find(_ code: String) -> CourierCycle?
        func save(_ item: CourierCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CourierCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierCycleStore: CourierCycleStore {
        var items: [String: CourierCycle]
        var order: [String]

        init(items: [String: CourierCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierCycle) {
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

        func list() -> [CourierCycle] {
            var out: [CourierCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierCycleStore() -> any CourierCycleStore {
        return MemoryCourierCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierCycleStore: CourierCycleStore {
        var inner: MemoryCourierCycleStore
        var cache: TTLCache<CourierCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierCycleStore, cache: TTLCache<CourierCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierCycle? {
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

        func save(_ item: CourierCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierCycle] {
            return inner.list()
        }
    }

    static func newCachedCourierCycleStore(_ inner: MemoryCourierCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierCycleStore {
        return CachedCourierCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier cycles. Empty fields match all.
    final class CourierCycleQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierCycle]) -> [CourierCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierCycles(_ store: any CourierCycleStore, query: CourierCycleQuery) -> [CourierCycle] {
        return query.apply(store.list())
    }
}
