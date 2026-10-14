import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment plans by code.
    protocol AssessmentPlanStore {
        func find(_ code: String) -> AssessmentPlan?
        func save(_ item: AssessmentPlan)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentPlanStore: AssessmentPlanStore {
        var items: [String: AssessmentPlan]
        var order: [String]

        init(items: [String: AssessmentPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentPlan) {
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

        func list() -> [AssessmentPlan] {
            var out: [AssessmentPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentPlanStore() -> any AssessmentPlanStore {
        return MemoryAssessmentPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentPlanStore: AssessmentPlanStore {
        var inner: MemoryAssessmentPlanStore
        var cache: TTLCache<AssessmentPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentPlanStore, cache: TTLCache<AssessmentPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentPlan? {
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

        func save(_ item: AssessmentPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentPlan] {
            return inner.list()
        }
    }

    static func newCachedAssessmentPlanStore(_ inner: MemoryAssessmentPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentPlanStore {
        return CachedAssessmentPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment plans. Empty fields match all.
    final class AssessmentPlanQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentPlan]) -> [AssessmentPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentPlans(_ store: any AssessmentPlanStore, query: AssessmentPlanQuery) -> [AssessmentPlan] {
        return query.apply(store.list())
    }
}
