import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program entries by code.
    protocol ProgramEntryStore {
        func find(_ code: String) -> ProgramEntry?
        func save(_ item: ProgramEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramEntryStore: ProgramEntryStore {
        var items: [String: ProgramEntry]
        var order: [String]

        init(items: [String: ProgramEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramEntry) {
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

        func list() -> [ProgramEntry] {
            var out: [ProgramEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramEntryStore() -> any ProgramEntryStore {
        return MemoryProgramEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramEntryStore: ProgramEntryStore {
        var inner: MemoryProgramEntryStore
        var cache: TTLCache<ProgramEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramEntryStore, cache: TTLCache<ProgramEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramEntry? {
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

        func save(_ item: ProgramEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramEntry] {
            return inner.list()
        }
    }

    static func newCachedProgramEntryStore(_ inner: MemoryProgramEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramEntryStore {
        return CachedProgramEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program entries. Empty fields match all.
    final class ProgramEntryQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramEntry) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramEntry]) -> [ProgramEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramEntries(_ store: any ProgramEntryStore, query: ProgramEntryQuery) -> [ProgramEntry] {
        return query.apply(store.list())
    }
}
