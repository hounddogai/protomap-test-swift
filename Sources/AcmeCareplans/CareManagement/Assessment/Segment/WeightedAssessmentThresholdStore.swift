import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted assessment thresholds by code.
    protocol WeightedAssessmentThresholdStore {
        func find(_ code: String) -> WeightedAssessmentThreshold?
        func save(_ item: WeightedAssessmentThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAssessmentThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAssessmentThresholdStore: WeightedAssessmentThresholdStore {
        var items: [String: WeightedAssessmentThreshold]
        var order: [String]

        init(items: [String: WeightedAssessmentThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAssessmentThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAssessmentThreshold) {
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

        func list() -> [WeightedAssessmentThreshold] {
            var out: [WeightedAssessmentThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAssessmentThresholdStore() -> any WeightedAssessmentThresholdStore {
        return MemoryWeightedAssessmentThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAssessmentThresholdStore: WeightedAssessmentThresholdStore {
        var inner: MemoryWeightedAssessmentThresholdStore
        var cache: TTLCache<WeightedAssessmentThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAssessmentThresholdStore, cache: TTLCache<WeightedAssessmentThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAssessmentThreshold? {
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

        func save(_ item: WeightedAssessmentThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAssessmentThreshold] {
            return inner.list()
        }
    }

    static func newCachedWeightedAssessmentThresholdStore(_ inner: MemoryWeightedAssessmentThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAssessmentThresholdStore {
        return CachedWeightedAssessmentThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted assessment thresholds. Empty fields match all.
    final class WeightedAssessmentThresholdQuery {
        var facility: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRate: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAssessmentThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [WeightedAssessmentThreshold]) -> [WeightedAssessmentThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAssessmentThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAssessmentThresholds(_ store: any WeightedAssessmentThresholdStore, query: WeightedAssessmentThresholdQuery) -> [WeightedAssessmentThreshold] {
        return query.apply(store.list())
    }
}
