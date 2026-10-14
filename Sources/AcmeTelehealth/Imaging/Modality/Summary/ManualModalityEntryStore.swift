import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual modality entries by code.
    protocol ManualModalityEntryStore {
        func find(_ code: String) -> ManualModalityEntry?
        func save(_ item: ManualModalityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ManualModalityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualModalityEntryStore: ManualModalityEntryStore {
        var items: [String: ManualModalityEntry]
        var order: [String]

        init(items: [String: ManualModalityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualModalityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualModalityEntry) {
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

        func list() -> [ManualModalityEntry] {
            var out: [ManualModalityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualModalityEntryStore() -> any ManualModalityEntryStore {
        return MemoryManualModalityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualModalityEntryStore: ManualModalityEntryStore {
        var inner: MemoryManualModalityEntryStore
        var cache: TTLCache<ManualModalityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualModalityEntryStore, cache: TTLCache<ManualModalityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualModalityEntry? {
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

        func save(_ item: ManualModalityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualModalityEntry] {
            return inner.list()
        }
    }

    static func newCachedManualModalityEntryStore(_ inner: MemoryManualModalityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualModalityEntryStore {
        return CachedManualModalityEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual modality entries. Empty fields match all.
    final class ManualModalityEntryQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualModalityEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualModalityEntry]) -> [ManualModalityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualModalityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualModalityEntries(_ store: any ManualModalityEntryStore, query: ManualModalityEntryQuery) -> [ManualModalityEntry] {
        return query.apply(store.list())
    }
}
