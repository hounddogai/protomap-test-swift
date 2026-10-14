import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment budgets by code.
    protocol AssessmentBudgetStore {
        func find(_ code: String) -> AssessmentBudget?
        func save(_ item: AssessmentBudget)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentBudgetStore: AssessmentBudgetStore {
        var items: [String: AssessmentBudget]
        var order: [String]

        init(items: [String: AssessmentBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentBudget) {
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

        func list() -> [AssessmentBudget] {
            var out: [AssessmentBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentBudgetStore() -> any AssessmentBudgetStore {
        return MemoryAssessmentBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentBudgetStore: AssessmentBudgetStore {
        var inner: MemoryAssessmentBudgetStore
        var cache: TTLCache<AssessmentBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentBudgetStore, cache: TTLCache<AssessmentBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentBudget? {
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

        func save(_ item: AssessmentBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentBudget] {
            return inner.list()
        }
    }

    static func newCachedAssessmentBudgetStore(_ inner: MemoryAssessmentBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentBudgetStore {
        return CachedAssessmentBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment budgets. Empty fields match all.
    final class AssessmentBudgetQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentBudget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentBudget]) -> [AssessmentBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentBudgets(_ store: any AssessmentBudgetStore, query: AssessmentBudgetQuery) -> [AssessmentBudget] {
        return query.apply(store.list())
    }
}
