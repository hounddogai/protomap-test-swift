import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal read exceptions by code.
    protocol SeasonalReadExceptionStore {
        func find(_ code: String) -> SeasonalReadException?
        func save(_ item: SeasonalReadException)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReadException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReadExceptionStore: SeasonalReadExceptionStore {
        var items: [String: SeasonalReadException]
        var order: [String]

        init(items: [String: SeasonalReadException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReadException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReadException) {
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

        func list() -> [SeasonalReadException] {
            var out: [SeasonalReadException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReadExceptionStore() -> any SeasonalReadExceptionStore {
        return MemorySeasonalReadExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReadExceptionStore: SeasonalReadExceptionStore {
        var inner: MemorySeasonalReadExceptionStore
        var cache: TTLCache<SeasonalReadException>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReadExceptionStore, cache: TTLCache<SeasonalReadException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReadException? {
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

        func save(_ item: SeasonalReadException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReadException] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReadExceptionStore(_ inner: MemorySeasonalReadExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReadExceptionStore {
        return CachedSeasonalReadExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal read exceptions. Empty fields match all.
    final class SeasonalReadExceptionQuery {
        var country: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMargin: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReadException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalReadException]) -> [SeasonalReadException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReadException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReadExceptions(_ store: any SeasonalReadExceptionStore, query: SeasonalReadExceptionQuery) -> [SeasonalReadException] {
        return query.apply(store.list())
    }
}
