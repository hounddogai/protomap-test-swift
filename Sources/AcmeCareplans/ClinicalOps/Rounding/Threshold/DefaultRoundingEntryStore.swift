import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default rounding entries by code.
    protocol DefaultRoundingEntryStore {
        func find(_ code: String) -> DefaultRoundingEntry?
        func save(_ item: DefaultRoundingEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRoundingEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRoundingEntryStore: DefaultRoundingEntryStore {
        var items: [String: DefaultRoundingEntry]
        var order: [String]

        init(items: [String: DefaultRoundingEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRoundingEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRoundingEntry) {
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

        func list() -> [DefaultRoundingEntry] {
            var out: [DefaultRoundingEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRoundingEntryStore() -> any DefaultRoundingEntryStore {
        return MemoryDefaultRoundingEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRoundingEntryStore: DefaultRoundingEntryStore {
        var inner: MemoryDefaultRoundingEntryStore
        var cache: TTLCache<DefaultRoundingEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRoundingEntryStore, cache: TTLCache<DefaultRoundingEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRoundingEntry? {
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

        func save(_ item: DefaultRoundingEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRoundingEntry] {
            return inner.list()
        }
    }

    static func newCachedDefaultRoundingEntryStore(_ inner: MemoryDefaultRoundingEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRoundingEntryStore {
        return CachedDefaultRoundingEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default rounding entries. Empty fields match all.
    final class DefaultRoundingEntryQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRoundingEntry) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [DefaultRoundingEntry]) -> [DefaultRoundingEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRoundingEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRoundingEntries(_ store: any DefaultRoundingEntryStore, query: DefaultRoundingEntryQuery) -> [DefaultRoundingEntry] {
        return query.apply(store.list())
    }
}
