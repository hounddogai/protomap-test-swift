import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure metrics by code.
    protocol SeasonalClosureMetricStore {
        func find(_ code: String) -> SeasonalClosureMetric?
        func save(_ item: SeasonalClosureMetric)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureMetricStore: SeasonalClosureMetricStore {
        var items: [String: SeasonalClosureMetric]
        var order: [String]

        init(items: [String: SeasonalClosureMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureMetric) {
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

        func list() -> [SeasonalClosureMetric] {
            var out: [SeasonalClosureMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureMetricStore() -> any SeasonalClosureMetricStore {
        return MemorySeasonalClosureMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureMetricStore: SeasonalClosureMetricStore {
        var inner: MemorySeasonalClosureMetricStore
        var cache: TTLCache<SeasonalClosureMetric>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureMetricStore, cache: TTLCache<SeasonalClosureMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureMetric? {
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

        func save(_ item: SeasonalClosureMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureMetric] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureMetricStore(_ inner: MemorySeasonalClosureMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureMetricStore {
        return CachedSeasonalClosureMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure metrics. Empty fields match all.
    final class SeasonalClosureMetricQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureMetric) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalClosureMetric]) -> [SeasonalClosureMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureMetrics(_ store: any SeasonalClosureMetricStore, query: SeasonalClosureMetricQuery) -> [SeasonalClosureMetric] {
        return query.apply(store.list())
    }
}
