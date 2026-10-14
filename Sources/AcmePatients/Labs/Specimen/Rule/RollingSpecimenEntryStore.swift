import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling specimen entries by code.
    protocol RollingSpecimenEntryStore {
        func find(_ code: String) -> RollingSpecimenEntry?
        func save(_ item: RollingSpecimenEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RollingSpecimenEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingSpecimenEntryStore: RollingSpecimenEntryStore {
        var items: [String: RollingSpecimenEntry]
        var order: [String]

        init(items: [String: RollingSpecimenEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingSpecimenEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingSpecimenEntry) {
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

        func list() -> [RollingSpecimenEntry] {
            var out: [RollingSpecimenEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingSpecimenEntryStore() -> any RollingSpecimenEntryStore {
        return MemoryRollingSpecimenEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingSpecimenEntryStore: RollingSpecimenEntryStore {
        var inner: MemoryRollingSpecimenEntryStore
        var cache: TTLCache<RollingSpecimenEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingSpecimenEntryStore, cache: TTLCache<RollingSpecimenEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingSpecimenEntry? {
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

        func save(_ item: RollingSpecimenEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingSpecimenEntry] {
            return inner.list()
        }
    }

    static func newCachedRollingSpecimenEntryStore(_ inner: MemoryRollingSpecimenEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingSpecimenEntryStore {
        return CachedRollingSpecimenEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling specimen entries. Empty fields match all.
    final class RollingSpecimenEntryQuery {
        var facility: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingSpecimenEntry) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingSpecimenEntry]) -> [RollingSpecimenEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingSpecimenEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingSpecimenEntries(_ store: any RollingSpecimenEntryStore, query: RollingSpecimenEntryQuery) -> [RollingSpecimenEntry] {
        return query.apply(store.list())
    }
}
