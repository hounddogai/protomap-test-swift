import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement milestones by code.
    protocol StatementMilestoneStore {
        func find(_ code: String) -> StatementMilestone?
        func save(_ item: StatementMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [StatementMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementMilestoneStore: StatementMilestoneStore {
        var items: [String: StatementMilestone]
        var order: [String]

        init(items: [String: StatementMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementMilestone) {
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

        func list() -> [StatementMilestone] {
            var out: [StatementMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementMilestoneStore() -> any StatementMilestoneStore {
        return MemoryStatementMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementMilestoneStore: StatementMilestoneStore {
        var inner: MemoryStatementMilestoneStore
        var cache: TTLCache<StatementMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementMilestoneStore, cache: TTLCache<StatementMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementMilestone? {
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

        func save(_ item: StatementMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementMilestone] {
            return inner.list()
        }
    }

    static func newCachedStatementMilestoneStore(_ inner: MemoryStatementMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementMilestoneStore {
        return CachedStatementMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement milestones. Empty fields match all.
    final class StatementMilestoneQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementMilestone) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementMilestone]) -> [StatementMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementMilestones(_ store: any StatementMilestoneStore, query: StatementMilestoneQuery) -> [StatementMilestone] {
        return query.apply(store.list())
    }
}
