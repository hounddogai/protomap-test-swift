import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal care protocol baselines by code.
    protocol SeasonalCareProtocolBaselineStore {
        func find(_ code: String) -> SeasonalCareProtocolBaseline?
        func save(_ item: SeasonalCareProtocolBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareProtocolBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareProtocolBaselineStore: SeasonalCareProtocolBaselineStore {
        var items: [String: SeasonalCareProtocolBaseline]
        var order: [String]

        init(items: [String: SeasonalCareProtocolBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareProtocolBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareProtocolBaseline) {
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

        func list() -> [SeasonalCareProtocolBaseline] {
            var out: [SeasonalCareProtocolBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareProtocolBaselineStore() -> any SeasonalCareProtocolBaselineStore {
        return MemorySeasonalCareProtocolBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareProtocolBaselineStore: SeasonalCareProtocolBaselineStore {
        var inner: MemorySeasonalCareProtocolBaselineStore
        var cache: TTLCache<SeasonalCareProtocolBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareProtocolBaselineStore, cache: TTLCache<SeasonalCareProtocolBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareProtocolBaseline? {
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

        func save(_ item: SeasonalCareProtocolBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareProtocolBaseline] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareProtocolBaselineStore(_ inner: MemorySeasonalCareProtocolBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareProtocolBaselineStore {
        return CachedSeasonalCareProtocolBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care protocol baselines. Empty fields match all.
    final class SeasonalCareProtocolBaselineQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareProtocolBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareProtocolBaseline]) -> [SeasonalCareProtocolBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareProtocolBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareProtocolBaselines(_ store: any SeasonalCareProtocolBaselineStore, query: SeasonalCareProtocolBaselineQuery) -> [SeasonalCareProtocolBaseline] {
        return query.apply(store.list())
    }
}
