import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default courier milestones by code.
    protocol DefaultCourierMilestoneStore {
        func find(_ code: String) -> DefaultCourierMilestone?
        func save(_ item: DefaultCourierMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCourierMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCourierMilestoneStore: DefaultCourierMilestoneStore {
        var items: [String: DefaultCourierMilestone]
        var order: [String]

        init(items: [String: DefaultCourierMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCourierMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCourierMilestone) {
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

        func list() -> [DefaultCourierMilestone] {
            var out: [DefaultCourierMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCourierMilestoneStore() -> any DefaultCourierMilestoneStore {
        return MemoryDefaultCourierMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCourierMilestoneStore: DefaultCourierMilestoneStore {
        var inner: MemoryDefaultCourierMilestoneStore
        var cache: TTLCache<DefaultCourierMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCourierMilestoneStore, cache: TTLCache<DefaultCourierMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCourierMilestone? {
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

        func save(_ item: DefaultCourierMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCourierMilestone] {
            return inner.list()
        }
    }

    static func newCachedDefaultCourierMilestoneStore(_ inner: MemoryDefaultCourierMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCourierMilestoneStore {
        return CachedDefaultCourierMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default courier milestones. Empty fields match all.
    final class DefaultCourierMilestoneQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCourierMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DefaultCourierMilestone]) -> [DefaultCourierMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCourierMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCourierMilestones(_ store: any DefaultCourierMilestoneStore, query: DefaultCourierMilestoneQuery) -> [DefaultCourierMilestone] {
        return query.apply(store.list())
    }
}
