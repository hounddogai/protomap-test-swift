import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession milestones by code.
    protocol AccessionMilestoneStore {
        func find(_ code: String) -> AccessionMilestone?
        func save(_ item: AccessionMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionMilestoneStore: AccessionMilestoneStore {
        var items: [String: AccessionMilestone]
        var order: [String]

        init(items: [String: AccessionMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionMilestone) {
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

        func list() -> [AccessionMilestone] {
            var out: [AccessionMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionMilestoneStore() -> any AccessionMilestoneStore {
        return MemoryAccessionMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionMilestoneStore: AccessionMilestoneStore {
        var inner: MemoryAccessionMilestoneStore
        var cache: TTLCache<AccessionMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionMilestoneStore, cache: TTLCache<AccessionMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionMilestone? {
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

        func save(_ item: AccessionMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionMilestone] {
            return inner.list()
        }
    }

    static func newCachedAccessionMilestoneStore(_ inner: MemoryAccessionMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionMilestoneStore {
        return CachedAccessionMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession milestones. Empty fields match all.
    final class AccessionMilestoneQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionMilestone]) -> [AccessionMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionMilestones(_ store: any AccessionMilestoneStore, query: AccessionMilestoneQuery) -> [AccessionMilestone] {
        return query.apply(store.list())
    }
}
