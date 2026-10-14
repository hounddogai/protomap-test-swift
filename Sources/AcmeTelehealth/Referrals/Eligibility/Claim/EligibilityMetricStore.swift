import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility metrics by code.
    protocol EligibilityMetricStore {
        func find(_ code: String) -> EligibilityMetric?
        func save(_ item: EligibilityMetric)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityMetricStore: EligibilityMetricStore {
        var items: [String: EligibilityMetric]
        var order: [String]

        init(items: [String: EligibilityMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityMetric) {
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

        func list() -> [EligibilityMetric] {
            var out: [EligibilityMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityMetricStore() -> any EligibilityMetricStore {
        return MemoryEligibilityMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityMetricStore: EligibilityMetricStore {
        var inner: MemoryEligibilityMetricStore
        var cache: TTLCache<EligibilityMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityMetricStore, cache: TTLCache<EligibilityMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityMetric? {
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

        func save(_ item: EligibilityMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityMetric] {
            return inner.list()
        }
    }

    static func newCachedEligibilityMetricStore(_ inner: MemoryEligibilityMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityMetricStore {
        return CachedEligibilityMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility metrics. Empty fields match all.
    final class EligibilityMetricQuery {
        var source: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityMetric) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [EligibilityMetric]) -> [EligibilityMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityMetrics(_ store: any EligibilityMetricStore, query: EligibilityMetricQuery) -> [EligibilityMetric] {
        return query.apply(store.list())
    }
}
