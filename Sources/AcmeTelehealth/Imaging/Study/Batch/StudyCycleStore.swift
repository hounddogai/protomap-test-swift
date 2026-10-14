import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study cycles by code.
    protocol StudyCycleStore {
        func find(_ code: String) -> StudyCycle?
        func save(_ item: StudyCycle)
        func remove(_ code: String) -> Bool
        func list() -> [StudyCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyCycleStore: StudyCycleStore {
        var items: [String: StudyCycle]
        var order: [String]

        init(items: [String: StudyCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyCycle) {
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

        func list() -> [StudyCycle] {
            var out: [StudyCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyCycleStore() -> any StudyCycleStore {
        return MemoryStudyCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyCycleStore: StudyCycleStore {
        var inner: MemoryStudyCycleStore
        var cache: TTLCache<StudyCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyCycleStore, cache: TTLCache<StudyCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyCycle? {
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

        func save(_ item: StudyCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyCycle] {
            return inner.list()
        }
    }

    static func newCachedStudyCycleStore(_ inner: MemoryStudyCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyCycleStore {
        return CachedStudyCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study cycles. Empty fields match all.
    final class StudyCycleQuery {
        var facility: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [StudyCycle]) -> [StudyCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyCycles(_ store: any StudyCycleStore, query: StudyCycleQuery) -> [StudyCycle] {
        return query.apply(store.list())
    }
}
