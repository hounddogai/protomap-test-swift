import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment variances by code.
    protocol AssessmentVarianceStore {
        func find(_ code: String) -> AssessmentVariance?
        func save(_ item: AssessmentVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentVarianceStore: AssessmentVarianceStore {
        var items: [String: AssessmentVariance]
        var order: [String]

        init(items: [String: AssessmentVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentVariance) {
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

        func list() -> [AssessmentVariance] {
            var out: [AssessmentVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentVarianceStore() -> any AssessmentVarianceStore {
        return MemoryAssessmentVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentVarianceStore: AssessmentVarianceStore {
        var inner: MemoryAssessmentVarianceStore
        var cache: TTLCache<AssessmentVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentVarianceStore, cache: TTLCache<AssessmentVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentVariance? {
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

        func save(_ item: AssessmentVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentVariance] {
            return inner.list()
        }
    }

    static func newCachedAssessmentVarianceStore(_ inner: MemoryAssessmentVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentVarianceStore {
        return CachedAssessmentVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment variances. Empty fields match all.
    final class AssessmentVarianceQuery {
        var region: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMargin: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentVariance) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentVariance]) -> [AssessmentVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentVariances(_ store: any AssessmentVarianceStore, query: AssessmentVarianceQuery) -> [AssessmentVariance] {
        return query.apply(store.list())
    }
}
