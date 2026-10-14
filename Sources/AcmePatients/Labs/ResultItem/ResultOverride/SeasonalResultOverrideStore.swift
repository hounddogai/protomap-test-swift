import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal result overrides by code.
    protocol SeasonalResultOverrideStore {
        func find(_ code: String) -> SeasonalResultOverride?
        func save(_ item: SeasonalResultOverride)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalResultOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalResultOverrideStore: SeasonalResultOverrideStore {
        var items: [String: SeasonalResultOverride]
        var order: [String]

        init(items: [String: SeasonalResultOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalResultOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalResultOverride) {
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

        func list() -> [SeasonalResultOverride] {
            var out: [SeasonalResultOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalResultOverrideStore() -> any SeasonalResultOverrideStore {
        return MemorySeasonalResultOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalResultOverrideStore: SeasonalResultOverrideStore {
        var inner: MemorySeasonalResultOverrideStore
        var cache: TTLCache<SeasonalResultOverride>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalResultOverrideStore, cache: TTLCache<SeasonalResultOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalResultOverride? {
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

        func save(_ item: SeasonalResultOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalResultOverride] {
            return inner.list()
        }
    }

    static func newCachedSeasonalResultOverrideStore(_ inner: MemorySeasonalResultOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalResultOverrideStore {
        return CachedSeasonalResultOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal result overrides. Empty fields match all.
    final class SeasonalResultOverrideQuery {
        var facility: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minWeight: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalResultOverride) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalResultOverride]) -> [SeasonalResultOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalResultOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalResultOverrides(_ store: any SeasonalResultOverrideStore, query: SeasonalResultOverrideQuery) -> [SeasonalResultOverride] {
        return query.apply(store.list())
    }
}
