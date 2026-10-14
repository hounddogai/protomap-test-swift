import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment metrics by code.
    protocol AssessmentMetricStore {
        func find(_ code: String) -> AssessmentMetric?
        func save(_ item: AssessmentMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentMetricStore: AssessmentMetricStore {
        var items: [String: AssessmentMetric]
        var order: [String]

        init(items: [String: AssessmentMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentMetric) {
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

        func list() -> [AssessmentMetric] {
            var out: [AssessmentMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentMetricStore() -> any AssessmentMetricStore {
        return MemoryAssessmentMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentMetricStore: AssessmentMetricStore {
        var inner: MemoryAssessmentMetricStore
        var cache: TTLCache<AssessmentMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentMetricStore, cache: TTLCache<AssessmentMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentMetric? {
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

        func save(_ item: AssessmentMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentMetric] {
            return inner.list()
        }
    }

    static func newCachedAssessmentMetricStore(_ inner: MemoryAssessmentMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentMetricStore {
        return CachedAssessmentMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment metrics. Empty fields match all.
    final class AssessmentMetricQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [AssessmentMetric]) -> [AssessmentMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentMetrics(_ store: any AssessmentMetricStore, query: AssessmentMetricQuery) -> [AssessmentMetric] {
        return query.apply(store.list())
    }
}
