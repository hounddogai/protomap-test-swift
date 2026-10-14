import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier windows by code.
    protocol CourierWindowStore {
        func find(_ code: String) -> CourierWindow?
        func save(_ item: CourierWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CourierWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierWindowStore: CourierWindowStore {
        var items: [String: CourierWindow]
        var order: [String]

        init(items: [String: CourierWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierWindow) {
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

        func list() -> [CourierWindow] {
            var out: [CourierWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierWindowStore() -> any CourierWindowStore {
        return MemoryCourierWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierWindowStore: CourierWindowStore {
        var inner: MemoryCourierWindowStore
        var cache: TTLCache<CourierWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierWindowStore, cache: TTLCache<CourierWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierWindow? {
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

        func save(_ item: CourierWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierWindow] {
            return inner.list()
        }
    }

    static func newCachedCourierWindowStore(_ inner: MemoryCourierWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierWindowStore {
        return CachedCourierWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier windows. Empty fields match all.
    final class CourierWindowQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierWindow]) -> [CourierWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierWindows(_ store: any CourierWindowStore, query: CourierWindowQuery) -> [CourierWindow] {
        return query.apply(store.list())
    }
}
