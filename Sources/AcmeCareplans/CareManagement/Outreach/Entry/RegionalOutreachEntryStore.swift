import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional outreach entries by code.
    protocol RegionalOutreachEntryStore {
        func find(_ code: String) -> RegionalOutreachEntry?
        func save(_ item: RegionalOutreachEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOutreachEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOutreachEntryStore: RegionalOutreachEntryStore {
        var items: [String: RegionalOutreachEntry]
        var order: [String]

        init(items: [String: RegionalOutreachEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOutreachEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOutreachEntry) {
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

        func list() -> [RegionalOutreachEntry] {
            var out: [RegionalOutreachEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOutreachEntryStore() -> any RegionalOutreachEntryStore {
        return MemoryRegionalOutreachEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOutreachEntryStore: RegionalOutreachEntryStore {
        var inner: MemoryRegionalOutreachEntryStore
        var cache: TTLCache<RegionalOutreachEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOutreachEntryStore, cache: TTLCache<RegionalOutreachEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOutreachEntry? {
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

        func save(_ item: RegionalOutreachEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOutreachEntry] {
            return inner.list()
        }
    }

    static func newCachedRegionalOutreachEntryStore(_ inner: MemoryRegionalOutreachEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOutreachEntryStore {
        return CachedRegionalOutreachEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional outreach entries. Empty fields match all.
    final class RegionalOutreachEntryQuery {
        var unit: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRevision: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOutreachEntry) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RegionalOutreachEntry]) -> [RegionalOutreachEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOutreachEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOutreachEntries(_ store: any RegionalOutreachEntryStore, query: RegionalOutreachEntryQuery) -> [RegionalOutreachEntry] {
        return query.apply(store.list())
    }
}
