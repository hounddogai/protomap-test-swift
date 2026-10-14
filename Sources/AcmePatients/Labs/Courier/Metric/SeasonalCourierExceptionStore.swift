import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal courier exceptions by code.
    protocol SeasonalCourierExceptionStore {
        func find(_ code: String) -> SeasonalCourierException?
        func save(_ item: SeasonalCourierException)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCourierException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCourierExceptionStore: SeasonalCourierExceptionStore {
        var items: [String: SeasonalCourierException]
        var order: [String]

        init(items: [String: SeasonalCourierException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCourierException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCourierException) {
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

        func list() -> [SeasonalCourierException] {
            var out: [SeasonalCourierException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCourierExceptionStore() -> any SeasonalCourierExceptionStore {
        return MemorySeasonalCourierExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCourierExceptionStore: SeasonalCourierExceptionStore {
        var inner: MemorySeasonalCourierExceptionStore
        var cache: TTLCache<SeasonalCourierException>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCourierExceptionStore, cache: TTLCache<SeasonalCourierException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCourierException? {
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

        func save(_ item: SeasonalCourierException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCourierException] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCourierExceptionStore(_ inner: MemorySeasonalCourierExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCourierExceptionStore {
        return CachedSeasonalCourierExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal courier exceptions. Empty fields match all.
    final class SeasonalCourierExceptionQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCourierException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCourierException]) -> [SeasonalCourierException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCourierException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCourierExceptions(_ store: any SeasonalCourierExceptionStore, query: SeasonalCourierExceptionQuery) -> [SeasonalCourierException] {
        return query.apply(store.list())
    }
}
