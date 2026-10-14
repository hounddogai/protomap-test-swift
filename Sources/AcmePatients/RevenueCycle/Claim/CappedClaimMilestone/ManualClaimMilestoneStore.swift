import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual claim milestones by code.
    protocol ManualClaimMilestoneStore {
        func find(_ code: String) -> ManualClaimMilestone?
        func save(_ item: ManualClaimMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ManualClaimMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualClaimMilestoneStore: ManualClaimMilestoneStore {
        var items: [String: ManualClaimMilestone]
        var order: [String]

        init(items: [String: ManualClaimMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualClaimMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualClaimMilestone) {
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

        func list() -> [ManualClaimMilestone] {
            var out: [ManualClaimMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualClaimMilestoneStore() -> any ManualClaimMilestoneStore {
        return MemoryManualClaimMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualClaimMilestoneStore: ManualClaimMilestoneStore {
        var inner: MemoryManualClaimMilestoneStore
        var cache: TTLCache<ManualClaimMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualClaimMilestoneStore, cache: TTLCache<ManualClaimMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualClaimMilestone? {
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

        func save(_ item: ManualClaimMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualClaimMilestone] {
            return inner.list()
        }
    }

    static func newCachedManualClaimMilestoneStore(_ inner: MemoryManualClaimMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualClaimMilestoneStore {
        return CachedManualClaimMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual claim milestones. Empty fields match all.
    final class ManualClaimMilestoneQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualClaimMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualClaimMilestone]) -> [ManualClaimMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualClaimMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualClaimMilestones(_ store: any ManualClaimMilestoneStore, query: ManualClaimMilestoneQuery) -> [ManualClaimMilestone] {
        return query.apply(store.list())
    }
}
