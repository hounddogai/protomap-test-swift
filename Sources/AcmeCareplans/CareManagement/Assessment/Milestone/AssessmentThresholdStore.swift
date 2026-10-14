import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment thresholds by code.
    protocol AssessmentThresholdStore {
        func find(_ code: String) -> AssessmentThreshold?
        func save(_ item: AssessmentThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentThresholdStore: AssessmentThresholdStore {
        var items: [String: AssessmentThreshold]
        var order: [String]

        init(items: [String: AssessmentThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentThreshold) {
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

        func list() -> [AssessmentThreshold] {
            var out: [AssessmentThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentThresholdStore() -> any AssessmentThresholdStore {
        return MemoryAssessmentThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentThresholdStore: AssessmentThresholdStore {
        var inner: MemoryAssessmentThresholdStore
        var cache: TTLCache<AssessmentThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentThresholdStore, cache: TTLCache<AssessmentThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentThreshold? {
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

        func save(_ item: AssessmentThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentThreshold] {
            return inner.list()
        }
    }

    static func newCachedAssessmentThresholdStore(_ inner: MemoryAssessmentThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentThresholdStore {
        return CachedAssessmentThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment thresholds. Empty fields match all.
    final class AssessmentThresholdQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentThreshold]) -> [AssessmentThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentThresholds(_ store: any AssessmentThresholdStore, query: AssessmentThresholdQuery) -> [AssessmentThreshold] {
        return query.apply(store.list())
    }
}
