import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled denial metrics by code.
    protocol ScheduledDenialMetricStore {
        func find(_ code: String) -> ScheduledDenialMetric?
        func save(_ item: ScheduledDenialMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledDenialMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledDenialMetricStore: ScheduledDenialMetricStore {
        var items: [String: ScheduledDenialMetric]
        var order: [String]

        init(items: [String: ScheduledDenialMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledDenialMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledDenialMetric) {
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

        func list() -> [ScheduledDenialMetric] {
            var out: [ScheduledDenialMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledDenialMetricStore() -> any ScheduledDenialMetricStore {
        return MemoryScheduledDenialMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledDenialMetricStore: ScheduledDenialMetricStore {
        var inner: MemoryScheduledDenialMetricStore
        var cache: TTLCache<ScheduledDenialMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledDenialMetricStore, cache: TTLCache<ScheduledDenialMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledDenialMetric? {
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

        func save(_ item: ScheduledDenialMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledDenialMetric] {
            return inner.list()
        }
    }

    static func newCachedScheduledDenialMetricStore(_ inner: MemoryScheduledDenialMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledDenialMetricStore {
        return CachedScheduledDenialMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled denial metrics. Empty fields match all.
    final class ScheduledDenialMetricQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledDenialMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledDenialMetric]) -> [ScheduledDenialMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledDenialMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledDenialMetrics(_ store: any ScheduledDenialMetricStore, query: ScheduledDenialMetricQuery) -> [ScheduledDenialMetric] {
        return query.apply(store.list())
    }
}
