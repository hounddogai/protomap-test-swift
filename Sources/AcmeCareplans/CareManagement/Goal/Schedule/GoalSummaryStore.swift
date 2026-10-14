import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal summaries by code.
    protocol GoalSummaryStore {
        func find(_ code: String) -> GoalSummary?
        func save(_ item: GoalSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GoalSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalSummaryStore: GoalSummaryStore {
        var items: [String: GoalSummary]
        var order: [String]

        init(items: [String: GoalSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalSummary) {
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

        func list() -> [GoalSummary] {
            var out: [GoalSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalSummaryStore() -> any GoalSummaryStore {
        return MemoryGoalSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalSummaryStore: GoalSummaryStore {
        var inner: MemoryGoalSummaryStore
        var cache: TTLCache<GoalSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalSummaryStore, cache: TTLCache<GoalSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalSummary? {
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

        func save(_ item: GoalSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalSummary] {
            return inner.list()
        }
    }

    static func newCachedGoalSummaryStore(_ inner: MemoryGoalSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalSummaryStore {
        return CachedGoalSummaryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal summaries. Empty fields match all.
    final class GoalSummaryQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalSummary) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [GoalSummary]) -> [GoalSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalSummaries(_ store: any GoalSummaryStore, query: GoalSummaryQuery) -> [GoalSummary] {
        return query.apply(store.list())
    }
}
