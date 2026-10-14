import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual courier entries by code.
    protocol ManualCourierEntryStore {
        func find(_ code: String) -> ManualCourierEntry?
        func save(_ item: ManualCourierEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCourierEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCourierEntryStore: ManualCourierEntryStore {
        var items: [String: ManualCourierEntry]
        var order: [String]

        init(items: [String: ManualCourierEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCourierEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCourierEntry) {
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

        func list() -> [ManualCourierEntry] {
            var out: [ManualCourierEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCourierEntryStore() -> any ManualCourierEntryStore {
        return MemoryManualCourierEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCourierEntryStore: ManualCourierEntryStore {
        var inner: MemoryManualCourierEntryStore
        var cache: TTLCache<ManualCourierEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCourierEntryStore, cache: TTLCache<ManualCourierEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCourierEntry? {
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

        func save(_ item: ManualCourierEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCourierEntry] {
            return inner.list()
        }
    }

    static func newCachedManualCourierEntryStore(_ inner: MemoryManualCourierEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCourierEntryStore {
        return CachedManualCourierEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual courier entries. Empty fields match all.
    final class ManualCourierEntryQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCourierEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ManualCourierEntry]) -> [ManualCourierEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCourierEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCourierEntries(_ store: any ManualCourierEntryStore, query: ManualCourierEntryQuery) -> [ManualCourierEntry] {
        return query.apply(store.list())
    }
}
