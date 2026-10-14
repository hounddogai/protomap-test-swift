import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending credential entries by code.
    protocol PendingCredentialEntryStore {
        func find(_ code: String) -> PendingCredentialEntry?
        func save(_ item: PendingCredentialEntry)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCredentialEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCredentialEntryStore: PendingCredentialEntryStore {
        var items: [String: PendingCredentialEntry]
        var order: [String]

        init(items: [String: PendingCredentialEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCredentialEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCredentialEntry) {
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

        func list() -> [PendingCredentialEntry] {
            var out: [PendingCredentialEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCredentialEntryStore() -> any PendingCredentialEntryStore {
        return MemoryPendingCredentialEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCredentialEntryStore: PendingCredentialEntryStore {
        var inner: MemoryPendingCredentialEntryStore
        var cache: TTLCache<PendingCredentialEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCredentialEntryStore, cache: TTLCache<PendingCredentialEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCredentialEntry? {
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

        func save(_ item: PendingCredentialEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCredentialEntry] {
            return inner.list()
        }
    }

    static func newCachedPendingCredentialEntryStore(_ inner: MemoryPendingCredentialEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCredentialEntryStore {
        return CachedPendingCredentialEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending credential entries. Empty fields match all.
    final class PendingCredentialEntryQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCredentialEntry) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCredentialEntry]) -> [PendingCredentialEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCredentialEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCredentialEntries(_ store: any PendingCredentialEntryStore, query: PendingCredentialEntryQuery) -> [PendingCredentialEntry] {
        return query.apply(store.list())
    }
}
