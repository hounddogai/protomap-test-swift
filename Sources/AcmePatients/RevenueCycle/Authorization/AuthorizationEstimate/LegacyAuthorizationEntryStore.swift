import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy authorization entries by code.
    protocol LegacyAuthorizationEntryStore {
        func find(_ code: String) -> LegacyAuthorizationEntry?
        func save(_ item: LegacyAuthorizationEntry)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAuthorizationEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAuthorizationEntryStore: LegacyAuthorizationEntryStore {
        var items: [String: LegacyAuthorizationEntry]
        var order: [String]

        init(items: [String: LegacyAuthorizationEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAuthorizationEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAuthorizationEntry) {
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

        func list() -> [LegacyAuthorizationEntry] {
            var out: [LegacyAuthorizationEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAuthorizationEntryStore() -> any LegacyAuthorizationEntryStore {
        return MemoryLegacyAuthorizationEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAuthorizationEntryStore: LegacyAuthorizationEntryStore {
        var inner: MemoryLegacyAuthorizationEntryStore
        var cache: TTLCache<LegacyAuthorizationEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAuthorizationEntryStore, cache: TTLCache<LegacyAuthorizationEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAuthorizationEntry? {
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

        func save(_ item: LegacyAuthorizationEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAuthorizationEntry] {
            return inner.list()
        }
    }

    static func newCachedLegacyAuthorizationEntryStore(_ inner: MemoryLegacyAuthorizationEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAuthorizationEntryStore {
        return CachedLegacyAuthorizationEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy authorization entries. Empty fields match all.
    final class LegacyAuthorizationEntryQuery {
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

        func matches(_ item: LegacyAuthorizationEntry) -> Bool {
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

        func apply(_ items: [LegacyAuthorizationEntry]) -> [LegacyAuthorizationEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAuthorizationEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAuthorizationEntries(_ store: any LegacyAuthorizationEntryStore, query: LegacyAuthorizationEntryQuery) -> [LegacyAuthorizationEntry] {
        return query.apply(store.list())
    }
}
