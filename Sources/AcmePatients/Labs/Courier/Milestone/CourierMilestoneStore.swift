import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier milestones by code.
    protocol CourierMilestoneStore {
        func find(_ code: String) -> CourierMilestone?
        func save(_ item: CourierMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [CourierMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierMilestoneStore: CourierMilestoneStore {
        var items: [String: CourierMilestone]
        var order: [String]

        init(items: [String: CourierMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierMilestone) {
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

        func list() -> [CourierMilestone] {
            var out: [CourierMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierMilestoneStore() -> any CourierMilestoneStore {
        return MemoryCourierMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierMilestoneStore: CourierMilestoneStore {
        var inner: MemoryCourierMilestoneStore
        var cache: TTLCache<CourierMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierMilestoneStore, cache: TTLCache<CourierMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierMilestone? {
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

        func save(_ item: CourierMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierMilestone] {
            return inner.list()
        }
    }

    static func newCachedCourierMilestoneStore(_ inner: MemoryCourierMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierMilestoneStore {
        return CachedCourierMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier milestones. Empty fields match all.
    final class CourierMilestoneQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierMilestone) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [CourierMilestone]) -> [CourierMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierMilestones(_ store: any CourierMilestoneStore, query: CourierMilestoneQuery) -> [CourierMilestone] {
        return query.apply(store.list())
    }
}
