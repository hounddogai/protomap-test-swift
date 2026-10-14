import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps seasonal bed board scores by code.
    protocol SeasonalBedBoardScoreStore {
        func find(_ code: String) -> SeasonalBedBoardScore?
        func save(_ item: SeasonalBedBoardScore)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalBedBoardScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalBedBoardScoreStore: SeasonalBedBoardScoreStore {
        var items: [String: SeasonalBedBoardScore]
        var order: [String]

        init(items: [String: SeasonalBedBoardScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalBedBoardScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalBedBoardScore) {
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

        func list() -> [SeasonalBedBoardScore] {
            var out: [SeasonalBedBoardScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalBedBoardScoreStore() -> any SeasonalBedBoardScoreStore {
        return MemorySeasonalBedBoardScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalBedBoardScoreStore: SeasonalBedBoardScoreStore {
        var inner: MemorySeasonalBedBoardScoreStore
        var cache: TTLCache<SeasonalBedBoardScore>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalBedBoardScoreStore, cache: TTLCache<SeasonalBedBoardScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalBedBoardScore? {
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

        func save(_ item: SeasonalBedBoardScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalBedBoardScore] {
            return inner.list()
        }
    }

    static func newCachedSeasonalBedBoardScoreStore(_ inner: MemorySeasonalBedBoardScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalBedBoardScoreStore {
        return CachedSeasonalBedBoardScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal bed board scores. Empty fields match all.
    final class SeasonalBedBoardScoreQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalBedBoardScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalBedBoardScore]) -> [SeasonalBedBoardScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalBedBoardScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalBedBoardScores(_ store: any SeasonalBedBoardScoreStore, query: SeasonalBedBoardScoreQuery) -> [SeasonalBedBoardScore] {
        return query.apply(store.list())
    }
}
