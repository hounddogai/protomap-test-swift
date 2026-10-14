import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling order set windows by code.
    protocol RollingOrderSetWindowStore {
        func find(_ code: String) -> RollingOrderSetWindow?
        func save(_ item: RollingOrderSetWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RollingOrderSetWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingOrderSetWindowStore: RollingOrderSetWindowStore {
        var items: [String: RollingOrderSetWindow]
        var order: [String]

        init(items: [String: RollingOrderSetWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingOrderSetWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingOrderSetWindow) {
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

        func list() -> [RollingOrderSetWindow] {
            var out: [RollingOrderSetWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingOrderSetWindowStore() -> any RollingOrderSetWindowStore {
        return MemoryRollingOrderSetWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingOrderSetWindowStore: RollingOrderSetWindowStore {
        var inner: MemoryRollingOrderSetWindowStore
        var cache: TTLCache<RollingOrderSetWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingOrderSetWindowStore, cache: TTLCache<RollingOrderSetWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingOrderSetWindow? {
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

        func save(_ item: RollingOrderSetWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingOrderSetWindow] {
            return inner.list()
        }
    }

    static func newCachedRollingOrderSetWindowStore(_ inner: MemoryRollingOrderSetWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingOrderSetWindowStore {
        return CachedRollingOrderSetWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling order set windows. Empty fields match all.
    final class RollingOrderSetWindowQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingOrderSetWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RollingOrderSetWindow]) -> [RollingOrderSetWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingOrderSetWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingOrderSetWindows(_ store: any RollingOrderSetWindowStore, query: RollingOrderSetWindowQuery) -> [RollingOrderSetWindow] {
        return query.apply(store.list())
    }
}
