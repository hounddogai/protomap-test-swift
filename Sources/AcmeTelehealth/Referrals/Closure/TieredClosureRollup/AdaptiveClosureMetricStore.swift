import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive closure metrics by code.
    protocol AdaptiveClosureMetricStore {
        func find(_ code: String) -> AdaptiveClosureMetric?
        func save(_ item: AdaptiveClosureMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveClosureMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveClosureMetricStore: AdaptiveClosureMetricStore {
        var items: [String: AdaptiveClosureMetric]
        var order: [String]

        init(items: [String: AdaptiveClosureMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveClosureMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveClosureMetric) {
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

        func list() -> [AdaptiveClosureMetric] {
            var out: [AdaptiveClosureMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveClosureMetricStore() -> any AdaptiveClosureMetricStore {
        return MemoryAdaptiveClosureMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveClosureMetricStore: AdaptiveClosureMetricStore {
        var inner: MemoryAdaptiveClosureMetricStore
        var cache: TTLCache<AdaptiveClosureMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveClosureMetricStore, cache: TTLCache<AdaptiveClosureMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveClosureMetric? {
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

        func save(_ item: AdaptiveClosureMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveClosureMetric] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveClosureMetricStore(_ inner: MemoryAdaptiveClosureMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveClosureMetricStore {
        return CachedAdaptiveClosureMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive closure metrics. Empty fields match all.
    final class AdaptiveClosureMetricQuery {
        var unit: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCopay: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveClosureMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveClosureMetric]) -> [AdaptiveClosureMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveClosureMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveClosureMetrics(_ store: any AdaptiveClosureMetricStore, query: AdaptiveClosureMetricQuery) -> [AdaptiveClosureMetric] {
        return query.apply(store.list())
    }
}
