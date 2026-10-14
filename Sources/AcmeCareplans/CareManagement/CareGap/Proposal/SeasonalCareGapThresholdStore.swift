import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap thresholds by code.
    protocol SeasonalCareGapThresholdStore {
        func find(_ code: String) -> SeasonalCareGapThreshold?
        func save(_ item: SeasonalCareGapThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapThresholdStore: SeasonalCareGapThresholdStore {
        var items: [String: SeasonalCareGapThreshold]
        var order: [String]

        init(items: [String: SeasonalCareGapThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapThreshold) {
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

        func list() -> [SeasonalCareGapThreshold] {
            var out: [SeasonalCareGapThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapThresholdStore() -> any SeasonalCareGapThresholdStore {
        return MemorySeasonalCareGapThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapThresholdStore: SeasonalCareGapThresholdStore {
        var inner: MemorySeasonalCareGapThresholdStore
        var cache: TTLCache<SeasonalCareGapThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapThresholdStore, cache: TTLCache<SeasonalCareGapThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapThreshold? {
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

        func save(_ item: SeasonalCareGapThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapThreshold] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapThresholdStore(_ inner: MemorySeasonalCareGapThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapThresholdStore {
        return CachedSeasonalCareGapThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap thresholds. Empty fields match all.
    final class SeasonalCareGapThresholdQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapThreshold) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareGapThreshold]) -> [SeasonalCareGapThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapThresholds(_ store: any SeasonalCareGapThresholdStore, query: SeasonalCareGapThresholdQuery) -> [SeasonalCareGapThreshold] {
        return query.apply(store.list())
    }
}
