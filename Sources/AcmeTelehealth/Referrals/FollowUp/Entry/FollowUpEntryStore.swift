import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up entries by code.
    protocol FollowUpEntryStore {
        func find(_ code: String) -> FollowUpEntry?
        func save(_ item: FollowUpEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpEntryStore: FollowUpEntryStore {
        var items: [String: FollowUpEntry]
        var order: [String]

        init(items: [String: FollowUpEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpEntry) {
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

        func list() -> [FollowUpEntry] {
            var out: [FollowUpEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpEntryStore() -> any FollowUpEntryStore {
        return MemoryFollowUpEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpEntryStore: FollowUpEntryStore {
        var inner: MemoryFollowUpEntryStore
        var cache: TTLCache<FollowUpEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpEntryStore, cache: TTLCache<FollowUpEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpEntry? {
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

        func save(_ item: FollowUpEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpEntry] {
            return inner.list()
        }
    }

    static func newCachedFollowUpEntryStore(_ inner: MemoryFollowUpEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpEntryStore {
        return CachedFollowUpEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up entries. Empty fields match all.
    final class FollowUpEntryQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpEntry]) -> [FollowUpEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpEntries(_ store: any FollowUpEntryStore, query: FollowUpEntryQuery) -> [FollowUpEntry] {
        return query.apply(store.list())
    }
}
