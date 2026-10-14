import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense metrics by code.
    protocol DispenseMetricStore {
        func find(_ code: String) -> DispenseMetric?
        func save(_ item: DispenseMetric)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseMetricStore: DispenseMetricStore {
        var items: [String: DispenseMetric]
        var order: [String]

        init(items: [String: DispenseMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseMetric) {
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

        func list() -> [DispenseMetric] {
            var out: [DispenseMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseMetricStore() -> any DispenseMetricStore {
        return MemoryDispenseMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseMetricStore: DispenseMetricStore {
        var inner: MemoryDispenseMetricStore
        var cache: TTLCache<DispenseMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseMetricStore, cache: TTLCache<DispenseMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseMetric? {
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

        func save(_ item: DispenseMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseMetric] {
            return inner.list()
        }
    }

    static func newCachedDispenseMetricStore(_ inner: MemoryDispenseMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseMetricStore {
        return CachedDispenseMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense metrics. Empty fields match all.
    final class DispenseMetricQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseMetric]) -> [DispenseMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseMetrics(_ store: any DispenseMetricStore, query: DispenseMetricQuery) -> [DispenseMetric] {
        return query.apply(store.list())
    }
}
