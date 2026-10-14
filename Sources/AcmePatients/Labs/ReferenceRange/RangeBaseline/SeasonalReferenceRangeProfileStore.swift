import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal reference range profiles by code.
    protocol SeasonalReferenceRangeProfileStore {
        func find(_ code: String) -> SeasonalReferenceRangeProfile?
        func save(_ item: SeasonalReferenceRangeProfile)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReferenceRangeProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReferenceRangeProfileStore: SeasonalReferenceRangeProfileStore {
        var items: [String: SeasonalReferenceRangeProfile]
        var order: [String]

        init(items: [String: SeasonalReferenceRangeProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReferenceRangeProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReferenceRangeProfile) {
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

        func list() -> [SeasonalReferenceRangeProfile] {
            var out: [SeasonalReferenceRangeProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReferenceRangeProfileStore() -> any SeasonalReferenceRangeProfileStore {
        return MemorySeasonalReferenceRangeProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReferenceRangeProfileStore: SeasonalReferenceRangeProfileStore {
        var inner: MemorySeasonalReferenceRangeProfileStore
        var cache: TTLCache<SeasonalReferenceRangeProfile>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReferenceRangeProfileStore, cache: TTLCache<SeasonalReferenceRangeProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReferenceRangeProfile? {
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

        func save(_ item: SeasonalReferenceRangeProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReferenceRangeProfile] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReferenceRangeProfileStore(_ inner: MemorySeasonalReferenceRangeProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReferenceRangeProfileStore {
        return CachedSeasonalReferenceRangeProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal reference range profiles. Empty fields match all.
    final class SeasonalReferenceRangeProfileQuery {
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

        func matches(_ item: SeasonalReferenceRangeProfile) -> Bool {
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

        func apply(_ items: [SeasonalReferenceRangeProfile]) -> [SeasonalReferenceRangeProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReferenceRangeProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReferenceRangeProfiles(_ store: any SeasonalReferenceRangeProfileStore, query: SeasonalReferenceRangeProfileQuery) -> [SeasonalReferenceRangeProfile] {
        return query.apply(store.list())
    }
}
