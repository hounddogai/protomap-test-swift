import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network metrics by code.
    protocol NetworkMetricStore {
        func find(_ code: String) -> NetworkMetric?
        func save(_ item: NetworkMetric)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkMetricStore: NetworkMetricStore {
        var items: [String: NetworkMetric]
        var order: [String]

        init(items: [String: NetworkMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkMetric) {
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

        func list() -> [NetworkMetric] {
            var out: [NetworkMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkMetricStore() -> any NetworkMetricStore {
        return MemoryNetworkMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkMetricStore: NetworkMetricStore {
        var inner: MemoryNetworkMetricStore
        var cache: TTLCache<NetworkMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkMetricStore, cache: TTLCache<NetworkMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkMetric? {
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

        func save(_ item: NetworkMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkMetric] {
            return inner.list()
        }
    }

    static func newCachedNetworkMetricStore(_ inner: MemoryNetworkMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkMetricStore {
        return CachedNetworkMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network metrics. Empty fields match all.
    final class NetworkMetricQuery {
        var ward: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkMetric]) -> [NetworkMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkMetrics(_ store: any NetworkMetricStore, query: NetworkMetricQuery) -> [NetworkMetric] {
        return query.apply(store.list())
    }
}
