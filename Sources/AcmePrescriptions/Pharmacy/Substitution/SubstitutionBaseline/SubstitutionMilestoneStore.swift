import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution milestones by code.
    protocol SubstitutionMilestoneStore {
        func find(_ code: String) -> SubstitutionMilestone?
        func save(_ item: SubstitutionMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionMilestoneStore: SubstitutionMilestoneStore {
        var items: [String: SubstitutionMilestone]
        var order: [String]

        init(items: [String: SubstitutionMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionMilestone) {
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

        func list() -> [SubstitutionMilestone] {
            var out: [SubstitutionMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionMilestoneStore() -> any SubstitutionMilestoneStore {
        return MemorySubstitutionMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionMilestoneStore: SubstitutionMilestoneStore {
        var inner: MemorySubstitutionMilestoneStore
        var cache: TTLCache<SubstitutionMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionMilestoneStore, cache: TTLCache<SubstitutionMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionMilestone? {
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

        func save(_ item: SubstitutionMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionMilestone] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionMilestoneStore(_ inner: MemorySubstitutionMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionMilestoneStore {
        return CachedSubstitutionMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution milestones. Empty fields match all.
    final class SubstitutionMilestoneQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SubstitutionMilestone]) -> [SubstitutionMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionMilestones(_ store: any SubstitutionMilestoneStore, query: SubstitutionMilestoneQuery) -> [SubstitutionMilestone] {
        return query.apply(store.list())
    }
}
