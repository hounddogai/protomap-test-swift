import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual priority entries by code.
    protocol ManualPriorityEntryStore {
        func find(_ code: String) -> ManualPriorityEntry?
        func save(_ item: ManualPriorityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ManualPriorityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualPriorityEntryStore: ManualPriorityEntryStore {
        var items: [String: ManualPriorityEntry]
        var order: [String]

        init(items: [String: ManualPriorityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualPriorityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualPriorityEntry) {
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

        func list() -> [ManualPriorityEntry] {
            var out: [ManualPriorityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualPriorityEntryStore() -> any ManualPriorityEntryStore {
        return MemoryManualPriorityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualPriorityEntryStore: ManualPriorityEntryStore {
        var inner: MemoryManualPriorityEntryStore
        var cache: TTLCache<ManualPriorityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualPriorityEntryStore, cache: TTLCache<ManualPriorityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualPriorityEntry? {
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

        func save(_ item: ManualPriorityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualPriorityEntry] {
            return inner.list()
        }
    }

    static func newCachedManualPriorityEntryStore(_ inner: MemoryManualPriorityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualPriorityEntryStore {
        return CachedManualPriorityEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual priority entries. Empty fields match all.
    final class ManualPriorityEntryQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualPriorityEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualPriorityEntry]) -> [ManualPriorityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualPriorityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualPriorityEntries(_ store: any ManualPriorityEntryStore, query: ManualPriorityEntryQuery) -> [ManualPriorityEntry] {
        return query.apply(store.list())
    }
}
