import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap entries by code.
    protocol SeasonalCareGapEntryStore {
        func find(_ code: String) -> SeasonalCareGapEntry?
        func save(_ item: SeasonalCareGapEntry)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapEntryStore: SeasonalCareGapEntryStore {
        var items: [String: SeasonalCareGapEntry]
        var order: [String]

        init(items: [String: SeasonalCareGapEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapEntry) {
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

        func list() -> [SeasonalCareGapEntry] {
            var out: [SeasonalCareGapEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapEntryStore() -> any SeasonalCareGapEntryStore {
        return MemorySeasonalCareGapEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapEntryStore: SeasonalCareGapEntryStore {
        var inner: MemorySeasonalCareGapEntryStore
        var cache: TTLCache<SeasonalCareGapEntry>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapEntryStore, cache: TTLCache<SeasonalCareGapEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapEntry? {
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

        func save(_ item: SeasonalCareGapEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapEntry] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapEntryStore(_ inner: MemorySeasonalCareGapEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapEntryStore {
        return CachedSeasonalCareGapEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap entries. Empty fields match all.
    final class SeasonalCareGapEntryQuery {
        var ward: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVersion: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapEntry) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareGapEntry]) -> [SeasonalCareGapEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapEntries(_ store: any SeasonalCareGapEntryStore, query: SeasonalCareGapEntryQuery) -> [SeasonalCareGapEntry] {
        return query.apply(store.list())
    }
}
