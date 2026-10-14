import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal panel scores by code.
    protocol SeasonalPanelScoreStore {
        func find(_ code: String) -> SeasonalPanelScore?
        func save(_ item: SeasonalPanelScore)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalPanelScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalPanelScoreStore: SeasonalPanelScoreStore {
        var items: [String: SeasonalPanelScore]
        var order: [String]

        init(items: [String: SeasonalPanelScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalPanelScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalPanelScore) {
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

        func list() -> [SeasonalPanelScore] {
            var out: [SeasonalPanelScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalPanelScoreStore() -> any SeasonalPanelScoreStore {
        return MemorySeasonalPanelScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalPanelScoreStore: SeasonalPanelScoreStore {
        var inner: MemorySeasonalPanelScoreStore
        var cache: TTLCache<SeasonalPanelScore>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalPanelScoreStore, cache: TTLCache<SeasonalPanelScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalPanelScore? {
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

        func save(_ item: SeasonalPanelScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalPanelScore] {
            return inner.list()
        }
    }

    static func newCachedSeasonalPanelScoreStore(_ inner: MemorySeasonalPanelScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalPanelScoreStore {
        return CachedSeasonalPanelScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal panel scores. Empty fields match all.
    final class SeasonalPanelScoreQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalPanelScore) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalPanelScore]) -> [SeasonalPanelScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalPanelScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalPanelScores(_ store: any SeasonalPanelScoreStore, query: SeasonalPanelScoreQuery) -> [SeasonalPanelScore] {
        return query.apply(store.list())
    }
}
