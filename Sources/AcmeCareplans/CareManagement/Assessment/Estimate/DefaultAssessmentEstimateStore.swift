import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default assessment estimates by code.
    protocol DefaultAssessmentEstimateStore {
        func find(_ code: String) -> DefaultAssessmentEstimate?
        func save(_ item: DefaultAssessmentEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAssessmentEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAssessmentEstimateStore: DefaultAssessmentEstimateStore {
        var items: [String: DefaultAssessmentEstimate]
        var order: [String]

        init(items: [String: DefaultAssessmentEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAssessmentEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAssessmentEstimate) {
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

        func list() -> [DefaultAssessmentEstimate] {
            var out: [DefaultAssessmentEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAssessmentEstimateStore() -> any DefaultAssessmentEstimateStore {
        return MemoryDefaultAssessmentEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAssessmentEstimateStore: DefaultAssessmentEstimateStore {
        var inner: MemoryDefaultAssessmentEstimateStore
        var cache: TTLCache<DefaultAssessmentEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAssessmentEstimateStore, cache: TTLCache<DefaultAssessmentEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAssessmentEstimate? {
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

        func save(_ item: DefaultAssessmentEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAssessmentEstimate] {
            return inner.list()
        }
    }

    static func newCachedDefaultAssessmentEstimateStore(_ inner: MemoryDefaultAssessmentEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAssessmentEstimateStore {
        return CachedDefaultAssessmentEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default assessment estimates. Empty fields match all.
    final class DefaultAssessmentEstimateQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAssessmentEstimate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAssessmentEstimate]) -> [DefaultAssessmentEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAssessmentEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAssessmentEstimates(_ store: any DefaultAssessmentEstimateStore, query: DefaultAssessmentEstimateQuery) -> [DefaultAssessmentEstimate] {
        return query.apply(store.list())
    }
}
