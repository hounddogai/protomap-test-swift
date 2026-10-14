import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol metrics by code.
    protocol CareProtocolMetricStore {
        func find(_ code: String) -> CareProtocolMetric?
        func save(_ item: CareProtocolMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolMetricStore: CareProtocolMetricStore {
        var items: [String: CareProtocolMetric]
        var order: [String]

        init(items: [String: CareProtocolMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolMetric) {
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

        func list() -> [CareProtocolMetric] {
            var out: [CareProtocolMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolMetricStore() -> any CareProtocolMetricStore {
        return MemoryCareProtocolMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolMetricStore: CareProtocolMetricStore {
        var inner: MemoryCareProtocolMetricStore
        var cache: TTLCache<CareProtocolMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolMetricStore, cache: TTLCache<CareProtocolMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolMetric? {
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

        func save(_ item: CareProtocolMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolMetric] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolMetricStore(_ inner: MemoryCareProtocolMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolMetricStore {
        return CachedCareProtocolMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol metrics. Empty fields match all.
    final class CareProtocolMetricQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [CareProtocolMetric]) -> [CareProtocolMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolMetrics(_ store: any CareProtocolMetricStore, query: CareProtocolMetricQuery) -> [CareProtocolMetric] {
        return query.apply(store.list())
    }
}
