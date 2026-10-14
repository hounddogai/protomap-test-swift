import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure milestones by code.
    protocol ClosureMilestoneStore {
        func find(_ code: String) -> ClosureMilestone?
        func save(_ item: ClosureMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureMilestoneStore: ClosureMilestoneStore {
        var items: [String: ClosureMilestone]
        var order: [String]

        init(items: [String: ClosureMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureMilestone) {
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

        func list() -> [ClosureMilestone] {
            var out: [ClosureMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureMilestoneStore() -> any ClosureMilestoneStore {
        return MemoryClosureMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureMilestoneStore: ClosureMilestoneStore {
        var inner: MemoryClosureMilestoneStore
        var cache: TTLCache<ClosureMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureMilestoneStore, cache: TTLCache<ClosureMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureMilestone? {
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

        func save(_ item: ClosureMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureMilestone] {
            return inner.list()
        }
    }

    static func newCachedClosureMilestoneStore(_ inner: MemoryClosureMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureMilestoneStore {
        return CachedClosureMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure milestones. Empty fields match all.
    final class ClosureMilestoneQuery {
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

        func matches(_ item: ClosureMilestone) -> Bool {
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

        func apply(_ items: [ClosureMilestone]) -> [ClosureMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureMilestones(_ store: any ClosureMilestoneStore, query: ClosureMilestoneQuery) -> [ClosureMilestone] {
        return query.apply(store.list())
    }
}
