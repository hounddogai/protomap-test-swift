import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier entries by code.
    protocol CourierEntryStore {
        func find(_ code: String) -> CourierEntry?
        func save(_ item: CourierEntry)
        func remove(_ code: String) -> Bool
        func list() -> [CourierEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierEntryStore: CourierEntryStore {
        var items: [String: CourierEntry]
        var order: [String]

        init(items: [String: CourierEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierEntry) {
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

        func list() -> [CourierEntry] {
            var out: [CourierEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierEntryStore() -> any CourierEntryStore {
        return MemoryCourierEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierEntryStore: CourierEntryStore {
        var inner: MemoryCourierEntryStore
        var cache: TTLCache<CourierEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierEntryStore, cache: TTLCache<CourierEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierEntry? {
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

        func save(_ item: CourierEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierEntry] {
            return inner.list()
        }
    }

    static func newCachedCourierEntryStore(_ inner: MemoryCourierEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierEntryStore {
        return CachedCourierEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier entries. Empty fields match all.
    final class CourierEntryQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierEntry) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierEntry]) -> [CourierEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierEntries(_ store: any CourierEntryStore, query: CourierEntryQuery) -> [CourierEntry] {
        return query.apply(store.list())
    }
}
