import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation entries by code.
    protocol RevocationEntryStore {
        func find(_ code: String) -> RevocationEntry?
        func save(_ item: RevocationEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationEntryStore: RevocationEntryStore {
        var items: [String: RevocationEntry]
        var order: [String]

        init(items: [String: RevocationEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationEntry) {
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

        func list() -> [RevocationEntry] {
            var out: [RevocationEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationEntryStore() -> any RevocationEntryStore {
        return MemoryRevocationEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationEntryStore: RevocationEntryStore {
        var inner: MemoryRevocationEntryStore
        var cache: TTLCache<RevocationEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationEntryStore, cache: TTLCache<RevocationEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationEntry? {
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

        func save(_ item: RevocationEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationEntry] {
            return inner.list()
        }
    }

    static func newCachedRevocationEntryStore(_ inner: MemoryRevocationEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationEntryStore {
        return CachedRevocationEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation entries. Empty fields match all.
    final class RevocationEntryQuery {
        var locale: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minRate: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationEntry) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationEntry]) -> [RevocationEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationEntries(_ store: any RevocationEntryStore, query: RevocationEntryQuery) -> [RevocationEntry] {
        return query.apply(store.list())
    }
}
