import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge metrics by code.
    protocol ChargeMetricStore {
        func find(_ code: String) -> ChargeMetric?
        func save(_ item: ChargeMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeMetricStore: ChargeMetricStore {
        var items: [String: ChargeMetric]
        var order: [String]

        init(items: [String: ChargeMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeMetric) {
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

        func list() -> [ChargeMetric] {
            var out: [ChargeMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeMetricStore() -> any ChargeMetricStore {
        return MemoryChargeMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeMetricStore: ChargeMetricStore {
        var inner: MemoryChargeMetricStore
        var cache: TTLCache<ChargeMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeMetricStore, cache: TTLCache<ChargeMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeMetric? {
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

        func save(_ item: ChargeMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeMetric] {
            return inner.list()
        }
    }

    static func newCachedChargeMetricStore(_ inner: MemoryChargeMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeMetricStore {
        return CachedChargeMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge metrics. Empty fields match all.
    final class ChargeMetricQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeMetric]) -> [ChargeMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeMetrics(_ store: any ChargeMetricStore, query: ChargeMetricQuery) -> [ChargeMetric] {
        return query.apply(store.list())
    }
}
