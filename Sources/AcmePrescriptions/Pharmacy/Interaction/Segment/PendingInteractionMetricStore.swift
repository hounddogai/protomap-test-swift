import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending interaction metrics by code.
    protocol PendingInteractionMetricStore {
        func find(_ code: String) -> PendingInteractionMetric?
        func save(_ item: PendingInteractionMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingInteractionMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingInteractionMetricStore: PendingInteractionMetricStore {
        var items: [String: PendingInteractionMetric]
        var order: [String]

        init(items: [String: PendingInteractionMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingInteractionMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingInteractionMetric) {
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

        func list() -> [PendingInteractionMetric] {
            var out: [PendingInteractionMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingInteractionMetricStore() -> any PendingInteractionMetricStore {
        return MemoryPendingInteractionMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingInteractionMetricStore: PendingInteractionMetricStore {
        var inner: MemoryPendingInteractionMetricStore
        var cache: TTLCache<PendingInteractionMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingInteractionMetricStore, cache: TTLCache<PendingInteractionMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingInteractionMetric? {
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

        func save(_ item: PendingInteractionMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingInteractionMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingInteractionMetricStore(_ inner: MemoryPendingInteractionMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingInteractionMetricStore {
        return CachedPendingInteractionMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending interaction metrics. Empty fields match all.
    final class PendingInteractionMetricQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingInteractionMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingInteractionMetric]) -> [PendingInteractionMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingInteractionMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingInteractionMetrics(_ store: any PendingInteractionMetricStore, query: PendingInteractionMetricQuery) -> [PendingInteractionMetric] {
        return query.apply(store.list())
    }
}
