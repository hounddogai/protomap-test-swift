import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation milestones by code.
    protocol IsolationMilestoneStore {
        func find(_ code: String) -> IsolationMilestone?
        func save(_ item: IsolationMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationMilestoneStore: IsolationMilestoneStore {
        var items: [String: IsolationMilestone]
        var order: [String]

        init(items: [String: IsolationMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationMilestone) {
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

        func list() -> [IsolationMilestone] {
            var out: [IsolationMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationMilestoneStore() -> any IsolationMilestoneStore {
        return MemoryIsolationMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationMilestoneStore: IsolationMilestoneStore {
        var inner: MemoryIsolationMilestoneStore
        var cache: TTLCache<IsolationMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationMilestoneStore, cache: TTLCache<IsolationMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationMilestone? {
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

        func save(_ item: IsolationMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationMilestone] {
            return inner.list()
        }
    }

    static func newCachedIsolationMilestoneStore(_ inner: MemoryIsolationMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationMilestoneStore {
        return CachedIsolationMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation milestones. Empty fields match all.
    final class IsolationMilestoneQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationMilestone) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [IsolationMilestone]) -> [IsolationMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationMilestones(_ store: any IsolationMilestoneStore, query: IsolationMilestoneQuery) -> [IsolationMilestone] {
        return query.apply(store.list())
    }
}
