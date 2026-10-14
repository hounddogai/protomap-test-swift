import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction metrics by code.
    protocol InteractionMetricStore {
        func find(_ code: String) -> InteractionMetric?
        func save(_ item: InteractionMetric)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionMetricStore: InteractionMetricStore {
        var items: [String: InteractionMetric]
        var order: [String]

        init(items: [String: InteractionMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionMetric) {
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

        func list() -> [InteractionMetric] {
            var out: [InteractionMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionMetricStore() -> any InteractionMetricStore {
        return MemoryInteractionMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionMetricStore: InteractionMetricStore {
        var inner: MemoryInteractionMetricStore
        var cache: TTLCache<InteractionMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionMetricStore, cache: TTLCache<InteractionMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionMetric? {
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

        func save(_ item: InteractionMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionMetric] {
            return inner.list()
        }
    }

    static func newCachedInteractionMetricStore(_ inner: MemoryInteractionMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionMetricStore {
        return CachedInteractionMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction metrics. Empty fields match all.
    final class InteractionMetricQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionMetric]) -> [InteractionMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionMetrics(_ store: any InteractionMetricStore, query: InteractionMetricQuery) -> [InteractionMetric] {
        return query.apply(store.list())
    }
}
