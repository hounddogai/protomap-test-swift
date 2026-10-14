import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen entries by code.
    protocol SpecimenEntryStore {
        func find(_ code: String) -> SpecimenEntry?
        func save(_ item: SpecimenEntry)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenEntryStore: SpecimenEntryStore {
        var items: [String: SpecimenEntry]
        var order: [String]

        init(items: [String: SpecimenEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenEntry) {
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

        func list() -> [SpecimenEntry] {
            var out: [SpecimenEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenEntryStore() -> any SpecimenEntryStore {
        return MemorySpecimenEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenEntryStore: SpecimenEntryStore {
        var inner: MemorySpecimenEntryStore
        var cache: TTLCache<SpecimenEntry>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenEntryStore, cache: TTLCache<SpecimenEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenEntry? {
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

        func save(_ item: SpecimenEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenEntry] {
            return inner.list()
        }
    }

    static func newCachedSpecimenEntryStore(_ inner: MemorySpecimenEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenEntryStore {
        return CachedSpecimenEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen entries. Empty fields match all.
    final class SpecimenEntryQuery {
        var source: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenEntry) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenEntry]) -> [SpecimenEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenEntries(_ store: any SpecimenEntryStore, query: SpecimenEntryQuery) -> [SpecimenEntry] {
        return query.apply(store.list())
    }
}
