import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure entries by code.
    protocol SeasonalClosureEntryStore {
        func find(_ code: String) -> SeasonalClosureEntry?
        func save(_ item: SeasonalClosureEntry)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureEntryStore: SeasonalClosureEntryStore {
        var items: [String: SeasonalClosureEntry]
        var order: [String]

        init(items: [String: SeasonalClosureEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureEntry) {
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

        func list() -> [SeasonalClosureEntry] {
            var out: [SeasonalClosureEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureEntryStore() -> any SeasonalClosureEntryStore {
        return MemorySeasonalClosureEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureEntryStore: SeasonalClosureEntryStore {
        var inner: MemorySeasonalClosureEntryStore
        var cache: TTLCache<SeasonalClosureEntry>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureEntryStore, cache: TTLCache<SeasonalClosureEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureEntry? {
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

        func save(_ item: SeasonalClosureEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureEntry] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureEntryStore(_ inner: MemorySeasonalClosureEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureEntryStore {
        return CachedSeasonalClosureEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure entries. Empty fields match all.
    final class SeasonalClosureEntryQuery {
        var locale: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureEntry) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SeasonalClosureEntry]) -> [SeasonalClosureEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureEntries(_ store: any SeasonalClosureEntryStore, query: SeasonalClosureEntryQuery) -> [SeasonalClosureEntry] {
        return query.apply(store.list())
    }
}
