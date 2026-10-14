import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive assessment metrics by code.
    protocol AdaptiveAssessmentMetricStore {
        func find(_ code: String) -> AdaptiveAssessmentMetric?
        func save(_ item: AdaptiveAssessmentMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAssessmentMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAssessmentMetricStore: AdaptiveAssessmentMetricStore {
        var items: [String: AdaptiveAssessmentMetric]
        var order: [String]

        init(items: [String: AdaptiveAssessmentMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAssessmentMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAssessmentMetric) {
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

        func list() -> [AdaptiveAssessmentMetric] {
            var out: [AdaptiveAssessmentMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAssessmentMetricStore() -> any AdaptiveAssessmentMetricStore {
        return MemoryAdaptiveAssessmentMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAssessmentMetricStore: AdaptiveAssessmentMetricStore {
        var inner: MemoryAdaptiveAssessmentMetricStore
        var cache: TTLCache<AdaptiveAssessmentMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAssessmentMetricStore, cache: TTLCache<AdaptiveAssessmentMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAssessmentMetric? {
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

        func save(_ item: AdaptiveAssessmentMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAssessmentMetric] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAssessmentMetricStore(_ inner: MemoryAdaptiveAssessmentMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAssessmentMetricStore {
        return CachedAdaptiveAssessmentMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive assessment metrics. Empty fields match all.
    final class AdaptiveAssessmentMetricQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAssessmentMetric) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveAssessmentMetric]) -> [AdaptiveAssessmentMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAssessmentMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAssessmentMetrics(_ store: any AdaptiveAssessmentMetricStore, query: AdaptiveAssessmentMetricQuery) -> [AdaptiveAssessmentMetric] {
        return query.apply(store.list())
    }
}
