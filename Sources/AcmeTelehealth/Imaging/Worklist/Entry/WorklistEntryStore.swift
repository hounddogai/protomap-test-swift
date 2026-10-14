import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist entries by code.
    protocol WorklistEntryStore {
        func find(_ code: String) -> WorklistEntry?
        func save(_ item: WorklistEntry)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistEntryStore: WorklistEntryStore {
        var items: [String: WorklistEntry]
        var order: [String]

        init(items: [String: WorklistEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistEntry) {
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

        func list() -> [WorklistEntry] {
            var out: [WorklistEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistEntryStore() -> any WorklistEntryStore {
        return MemoryWorklistEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistEntryStore: WorklistEntryStore {
        var inner: MemoryWorklistEntryStore
        var cache: TTLCache<WorklistEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistEntryStore, cache: TTLCache<WorklistEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistEntry? {
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

        func save(_ item: WorklistEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistEntry] {
            return inner.list()
        }
    }

    static func newCachedWorklistEntryStore(_ inner: MemoryWorklistEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistEntryStore {
        return CachedWorklistEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist entries. Empty fields match all.
    final class WorklistEntryQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistEntry]) -> [WorklistEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistEntries(_ store: any WorklistEntryStore, query: WorklistEntryQuery) -> [WorklistEntry] {
        return query.apply(store.list())
    }
}
