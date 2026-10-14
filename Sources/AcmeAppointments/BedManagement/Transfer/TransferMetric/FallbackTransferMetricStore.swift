import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback transfer metrics by code.
    protocol FallbackTransferMetricStore {
        func find(_ code: String) -> FallbackTransferMetric?
        func save(_ item: FallbackTransferMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackTransferMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackTransferMetricStore: FallbackTransferMetricStore {
        var items: [String: FallbackTransferMetric]
        var order: [String]

        init(items: [String: FallbackTransferMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackTransferMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackTransferMetric) {
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

        func list() -> [FallbackTransferMetric] {
            var out: [FallbackTransferMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackTransferMetricStore() -> any FallbackTransferMetricStore {
        return MemoryFallbackTransferMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackTransferMetricStore: FallbackTransferMetricStore {
        var inner: MemoryFallbackTransferMetricStore
        var cache: TTLCache<FallbackTransferMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackTransferMetricStore, cache: TTLCache<FallbackTransferMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackTransferMetric? {
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

        func save(_ item: FallbackTransferMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackTransferMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackTransferMetricStore(_ inner: MemoryFallbackTransferMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackTransferMetricStore {
        return CachedFallbackTransferMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback transfer metrics. Empty fields match all.
    final class FallbackTransferMetricQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackTransferMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackTransferMetric]) -> [FallbackTransferMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackTransferMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackTransferMetrics(_ store: any FallbackTransferMetricStore, query: FallbackTransferMetricQuery) -> [FallbackTransferMetric] {
        return query.apply(store.list())
    }
}
