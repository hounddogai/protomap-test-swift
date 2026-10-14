import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global order set windows by code.
    protocol GlobalOrderSetWindowStore {
        func find(_ code: String) -> GlobalOrderSetWindow?
        func save(_ item: GlobalOrderSetWindow)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOrderSetWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOrderSetWindowStore: GlobalOrderSetWindowStore {
        var items: [String: GlobalOrderSetWindow]
        var order: [String]

        init(items: [String: GlobalOrderSetWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOrderSetWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOrderSetWindow) {
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

        func list() -> [GlobalOrderSetWindow] {
            var out: [GlobalOrderSetWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOrderSetWindowStore() -> any GlobalOrderSetWindowStore {
        return MemoryGlobalOrderSetWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOrderSetWindowStore: GlobalOrderSetWindowStore {
        var inner: MemoryGlobalOrderSetWindowStore
        var cache: TTLCache<GlobalOrderSetWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOrderSetWindowStore, cache: TTLCache<GlobalOrderSetWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOrderSetWindow? {
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

        func save(_ item: GlobalOrderSetWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOrderSetWindow] {
            return inner.list()
        }
    }

    static func newCachedGlobalOrderSetWindowStore(_ inner: MemoryGlobalOrderSetWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOrderSetWindowStore {
        return CachedGlobalOrderSetWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global order set windows. Empty fields match all.
    final class GlobalOrderSetWindowQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOrderSetWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [GlobalOrderSetWindow]) -> [GlobalOrderSetWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOrderSetWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOrderSetWindows(_ store: any GlobalOrderSetWindowStore, query: GlobalOrderSetWindowQuery) -> [GlobalOrderSetWindow] {
        return query.apply(store.list())
    }
}
