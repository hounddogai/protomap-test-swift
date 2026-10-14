import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending panel milestones by code.
    protocol PendingPanelMilestoneStore {
        func find(_ code: String) -> PendingPanelMilestone?
        func save(_ item: PendingPanelMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PendingPanelMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingPanelMilestoneStore: PendingPanelMilestoneStore {
        var items: [String: PendingPanelMilestone]
        var order: [String]

        init(items: [String: PendingPanelMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingPanelMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingPanelMilestone) {
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

        func list() -> [PendingPanelMilestone] {
            var out: [PendingPanelMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingPanelMilestoneStore() -> any PendingPanelMilestoneStore {
        return MemoryPendingPanelMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingPanelMilestoneStore: PendingPanelMilestoneStore {
        var inner: MemoryPendingPanelMilestoneStore
        var cache: TTLCache<PendingPanelMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingPanelMilestoneStore, cache: TTLCache<PendingPanelMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingPanelMilestone? {
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

        func save(_ item: PendingPanelMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingPanelMilestone] {
            return inner.list()
        }
    }

    static func newCachedPendingPanelMilestoneStore(_ inner: MemoryPendingPanelMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingPanelMilestoneStore {
        return CachedPendingPanelMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending panel milestones. Empty fields match all.
    final class PendingPanelMilestoneQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingPanelMilestone) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [PendingPanelMilestone]) -> [PendingPanelMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingPanelMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingPanelMilestones(_ store: any PendingPanelMilestoneStore, query: PendingPanelMilestoneQuery) -> [PendingPanelMilestone] {
        return query.apply(store.list())
    }
}
