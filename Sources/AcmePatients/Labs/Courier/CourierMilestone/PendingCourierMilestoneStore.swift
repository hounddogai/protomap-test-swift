import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending courier milestones by code.
    protocol PendingCourierMilestoneStore {
        func find(_ code: String) -> PendingCourierMilestone?
        func save(_ item: PendingCourierMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCourierMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCourierMilestoneStore: PendingCourierMilestoneStore {
        var items: [String: PendingCourierMilestone]
        var order: [String]

        init(items: [String: PendingCourierMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCourierMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCourierMilestone) {
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

        func list() -> [PendingCourierMilestone] {
            var out: [PendingCourierMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCourierMilestoneStore() -> any PendingCourierMilestoneStore {
        return MemoryPendingCourierMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCourierMilestoneStore: PendingCourierMilestoneStore {
        var inner: MemoryPendingCourierMilestoneStore
        var cache: TTLCache<PendingCourierMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCourierMilestoneStore, cache: TTLCache<PendingCourierMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCourierMilestone? {
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

        func save(_ item: PendingCourierMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCourierMilestone] {
            return inner.list()
        }
    }

    static func newCachedPendingCourierMilestoneStore(_ inner: MemoryPendingCourierMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCourierMilestoneStore {
        return CachedPendingCourierMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending courier milestones. Empty fields match all.
    final class PendingCourierMilestoneQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCourierMilestone) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCourierMilestone]) -> [PendingCourierMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCourierMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCourierMilestones(_ store: any PendingCourierMilestoneStore, query: PendingCourierMilestoneQuery) -> [PendingCourierMilestone] {
        return query.apply(store.list())
    }
}
