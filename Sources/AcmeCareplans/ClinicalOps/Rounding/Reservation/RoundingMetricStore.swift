import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding metrics by code.
    protocol RoundingMetricStore {
        func find(_ code: String) -> RoundingMetric?
        func save(_ item: RoundingMetric)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingMetricStore: RoundingMetricStore {
        var items: [String: RoundingMetric]
        var order: [String]

        init(items: [String: RoundingMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingMetric) {
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

        func list() -> [RoundingMetric] {
            var out: [RoundingMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingMetricStore() -> any RoundingMetricStore {
        return MemoryRoundingMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingMetricStore: RoundingMetricStore {
        var inner: MemoryRoundingMetricStore
        var cache: TTLCache<RoundingMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingMetricStore, cache: TTLCache<RoundingMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingMetric? {
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

        func save(_ item: RoundingMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingMetric] {
            return inner.list()
        }
    }

    static func newCachedRoundingMetricStore(_ inner: MemoryRoundingMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingMetricStore {
        return CachedRoundingMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding metrics. Empty fields match all.
    final class RoundingMetricQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingMetric]) -> [RoundingMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingMetrics(_ store: any RoundingMetricStore, query: RoundingMetricQuery) -> [RoundingMetric] {
        return query.apply(store.list())
    }
}
