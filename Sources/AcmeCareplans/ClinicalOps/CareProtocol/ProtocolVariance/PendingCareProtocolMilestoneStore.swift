import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending care protocol milestones by code.
    protocol PendingCareProtocolMilestoneStore {
        func find(_ code: String) -> PendingCareProtocolMilestone?
        func save(_ item: PendingCareProtocolMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCareProtocolMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCareProtocolMilestoneStore: PendingCareProtocolMilestoneStore {
        var items: [String: PendingCareProtocolMilestone]
        var order: [String]

        init(items: [String: PendingCareProtocolMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCareProtocolMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCareProtocolMilestone) {
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

        func list() -> [PendingCareProtocolMilestone] {
            var out: [PendingCareProtocolMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCareProtocolMilestoneStore() -> any PendingCareProtocolMilestoneStore {
        return MemoryPendingCareProtocolMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCareProtocolMilestoneStore: PendingCareProtocolMilestoneStore {
        var inner: MemoryPendingCareProtocolMilestoneStore
        var cache: TTLCache<PendingCareProtocolMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCareProtocolMilestoneStore, cache: TTLCache<PendingCareProtocolMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCareProtocolMilestone? {
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

        func save(_ item: PendingCareProtocolMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCareProtocolMilestone] {
            return inner.list()
        }
    }

    static func newCachedPendingCareProtocolMilestoneStore(_ inner: MemoryPendingCareProtocolMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCareProtocolMilestoneStore {
        return CachedPendingCareProtocolMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending care protocol milestones. Empty fields match all.
    final class PendingCareProtocolMilestoneQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCareProtocolMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [PendingCareProtocolMilestone]) -> [PendingCareProtocolMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCareProtocolMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCareProtocolMilestones(_ store: any PendingCareProtocolMilestoneStore, query: PendingCareProtocolMilestoneQuery) -> [PendingCareProtocolMilestone] {
        return query.apply(store.list())
    }
}
