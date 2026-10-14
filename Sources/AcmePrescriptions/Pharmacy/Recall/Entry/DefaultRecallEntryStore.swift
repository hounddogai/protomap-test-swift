import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default recall entries by code.
    protocol DefaultRecallEntryStore {
        func find(_ code: String) -> DefaultRecallEntry?
        func save(_ item: DefaultRecallEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRecallEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRecallEntryStore: DefaultRecallEntryStore {
        var items: [String: DefaultRecallEntry]
        var order: [String]

        init(items: [String: DefaultRecallEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRecallEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRecallEntry) {
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

        func list() -> [DefaultRecallEntry] {
            var out: [DefaultRecallEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRecallEntryStore() -> any DefaultRecallEntryStore {
        return MemoryDefaultRecallEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRecallEntryStore: DefaultRecallEntryStore {
        var inner: MemoryDefaultRecallEntryStore
        var cache: TTLCache<DefaultRecallEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRecallEntryStore, cache: TTLCache<DefaultRecallEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRecallEntry? {
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

        func save(_ item: DefaultRecallEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRecallEntry] {
            return inner.list()
        }
    }

    static func newCachedDefaultRecallEntryStore(_ inner: MemoryDefaultRecallEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRecallEntryStore {
        return CachedDefaultRecallEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default recall entries. Empty fields match all.
    final class DefaultRecallEntryQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRecallEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRecallEntry]) -> [DefaultRecallEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRecallEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRecallEntries(_ store: any DefaultRecallEntryStore, query: DefaultRecallEntryQuery) -> [DefaultRecallEntry] {
        return query.apply(store.list())
    }
}
