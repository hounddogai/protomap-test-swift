import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary denial metrics by code.
    protocol PrimaryDenialMetricStore {
        func find(_ code: String) -> PrimaryDenialMetric?
        func save(_ item: PrimaryDenialMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDenialMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDenialMetricStore: PrimaryDenialMetricStore {
        var items: [String: PrimaryDenialMetric]
        var order: [String]

        init(items: [String: PrimaryDenialMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDenialMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDenialMetric) {
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

        func list() -> [PrimaryDenialMetric] {
            var out: [PrimaryDenialMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDenialMetricStore() -> any PrimaryDenialMetricStore {
        return MemoryPrimaryDenialMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDenialMetricStore: PrimaryDenialMetricStore {
        var inner: MemoryPrimaryDenialMetricStore
        var cache: TTLCache<PrimaryDenialMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDenialMetricStore, cache: TTLCache<PrimaryDenialMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDenialMetric? {
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

        func save(_ item: PrimaryDenialMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDenialMetric] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDenialMetricStore(_ inner: MemoryPrimaryDenialMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDenialMetricStore {
        return CachedPrimaryDenialMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary denial metrics. Empty fields match all.
    final class PrimaryDenialMetricQuery {
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

        func matches(_ item: PrimaryDenialMetric) -> Bool {
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

        func apply(_ items: [PrimaryDenialMetric]) -> [PrimaryDenialMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDenialMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDenialMetrics(_ store: any PrimaryDenialMetricStore, query: PrimaryDenialMetricQuery) -> [PrimaryDenialMetric] {
        return query.apply(store.list())
    }
}
