import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive transfer metrics by code.
    protocol AdaptiveTransferMetricStore {
        func find(_ code: String) -> AdaptiveTransferMetric?
        func save(_ item: AdaptiveTransferMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveTransferMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveTransferMetricStore: AdaptiveTransferMetricStore {
        var items: [String: AdaptiveTransferMetric]
        var order: [String]

        init(items: [String: AdaptiveTransferMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveTransferMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveTransferMetric) {
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

        func list() -> [AdaptiveTransferMetric] {
            var out: [AdaptiveTransferMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveTransferMetricStore() -> any AdaptiveTransferMetricStore {
        return MemoryAdaptiveTransferMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveTransferMetricStore: AdaptiveTransferMetricStore {
        var inner: MemoryAdaptiveTransferMetricStore
        var cache: TTLCache<AdaptiveTransferMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveTransferMetricStore, cache: TTLCache<AdaptiveTransferMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveTransferMetric? {
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

        func save(_ item: AdaptiveTransferMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveTransferMetric] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveTransferMetricStore(_ inner: MemoryAdaptiveTransferMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveTransferMetricStore {
        return CachedAdaptiveTransferMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive transfer metrics. Empty fields match all.
    final class AdaptiveTransferMetricQuery {
        var segment: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveTransferMetric) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveTransferMetric]) -> [AdaptiveTransferMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveTransferMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveTransferMetrics(_ store: any AdaptiveTransferMetricStore, query: AdaptiveTransferMetricQuery) -> [AdaptiveTransferMetric] {
        return query.apply(store.list())
    }
}
