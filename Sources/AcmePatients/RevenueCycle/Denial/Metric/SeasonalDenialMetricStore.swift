import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal denial metrics by code.
    protocol SeasonalDenialMetricStore {
        func find(_ code: String) -> SeasonalDenialMetric?
        func save(_ item: SeasonalDenialMetric)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalDenialMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalDenialMetricStore: SeasonalDenialMetricStore {
        var items: [String: SeasonalDenialMetric]
        var order: [String]

        init(items: [String: SeasonalDenialMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalDenialMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalDenialMetric) {
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

        func list() -> [SeasonalDenialMetric] {
            var out: [SeasonalDenialMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalDenialMetricStore() -> any SeasonalDenialMetricStore {
        return MemorySeasonalDenialMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalDenialMetricStore: SeasonalDenialMetricStore {
        var inner: MemorySeasonalDenialMetricStore
        var cache: TTLCache<SeasonalDenialMetric>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalDenialMetricStore, cache: TTLCache<SeasonalDenialMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalDenialMetric? {
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

        func save(_ item: SeasonalDenialMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalDenialMetric] {
            return inner.list()
        }
    }

    static func newCachedSeasonalDenialMetricStore(_ inner: MemorySeasonalDenialMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalDenialMetricStore {
        return CachedSeasonalDenialMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal denial metrics. Empty fields match all.
    final class SeasonalDenialMetricQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalDenialMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalDenialMetric]) -> [SeasonalDenialMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalDenialMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalDenialMetrics(_ store: any SeasonalDenialMetricStore, query: SeasonalDenialMetricQuery) -> [SeasonalDenialMetric] {
        return query.apply(store.list())
    }
}
