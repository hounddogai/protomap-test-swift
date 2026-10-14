import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient recall milestones by code.
    protocol LenientRecallMilestoneStore {
        func find(_ code: String) -> LenientRecallMilestone?
        func save(_ item: LenientRecallMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRecallMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRecallMilestoneStore: LenientRecallMilestoneStore {
        var items: [String: LenientRecallMilestone]
        var order: [String]

        init(items: [String: LenientRecallMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRecallMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRecallMilestone) {
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

        func list() -> [LenientRecallMilestone] {
            var out: [LenientRecallMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRecallMilestoneStore() -> any LenientRecallMilestoneStore {
        return MemoryLenientRecallMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRecallMilestoneStore: LenientRecallMilestoneStore {
        var inner: MemoryLenientRecallMilestoneStore
        var cache: TTLCache<LenientRecallMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRecallMilestoneStore, cache: TTLCache<LenientRecallMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRecallMilestone? {
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

        func save(_ item: LenientRecallMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRecallMilestone] {
            return inner.list()
        }
    }

    static func newCachedLenientRecallMilestoneStore(_ inner: MemoryLenientRecallMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRecallMilestoneStore {
        return CachedLenientRecallMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient recall milestones. Empty fields match all.
    final class LenientRecallMilestoneQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRecallMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRecallMilestone]) -> [LenientRecallMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRecallMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRecallMilestones(_ store: any LenientRecallMilestoneStore, query: LenientRecallMilestoneQuery) -> [LenientRecallMilestone] {
        return query.apply(store.list())
    }
}
