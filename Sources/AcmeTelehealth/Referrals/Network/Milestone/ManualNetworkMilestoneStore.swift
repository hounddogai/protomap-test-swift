import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual network milestones by code.
    protocol ManualNetworkMilestoneStore {
        func find(_ code: String) -> ManualNetworkMilestone?
        func save(_ item: ManualNetworkMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ManualNetworkMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualNetworkMilestoneStore: ManualNetworkMilestoneStore {
        var items: [String: ManualNetworkMilestone]
        var order: [String]

        init(items: [String: ManualNetworkMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualNetworkMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualNetworkMilestone) {
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

        func list() -> [ManualNetworkMilestone] {
            var out: [ManualNetworkMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualNetworkMilestoneStore() -> any ManualNetworkMilestoneStore {
        return MemoryManualNetworkMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualNetworkMilestoneStore: ManualNetworkMilestoneStore {
        var inner: MemoryManualNetworkMilestoneStore
        var cache: TTLCache<ManualNetworkMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualNetworkMilestoneStore, cache: TTLCache<ManualNetworkMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualNetworkMilestone? {
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

        func save(_ item: ManualNetworkMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualNetworkMilestone] {
            return inner.list()
        }
    }

    static func newCachedManualNetworkMilestoneStore(_ inner: MemoryManualNetworkMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualNetworkMilestoneStore {
        return CachedManualNetworkMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual network milestones. Empty fields match all.
    final class ManualNetworkMilestoneQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualNetworkMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualNetworkMilestone]) -> [ManualNetworkMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualNetworkMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualNetworkMilestones(_ store: any ManualNetworkMilestoneStore, query: ManualNetworkMilestoneQuery) -> [ManualNetworkMilestone] {
        return query.apply(store.list())
    }
}
