import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient authorization milestones by code.
    protocol LenientAuthorizationMilestoneStore {
        func find(_ code: String) -> LenientAuthorizationMilestone?
        func save(_ item: LenientAuthorizationMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LenientAuthorizationMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientAuthorizationMilestoneStore: LenientAuthorizationMilestoneStore {
        var items: [String: LenientAuthorizationMilestone]
        var order: [String]

        init(items: [String: LenientAuthorizationMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientAuthorizationMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientAuthorizationMilestone) {
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

        func list() -> [LenientAuthorizationMilestone] {
            var out: [LenientAuthorizationMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientAuthorizationMilestoneStore() -> any LenientAuthorizationMilestoneStore {
        return MemoryLenientAuthorizationMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientAuthorizationMilestoneStore: LenientAuthorizationMilestoneStore {
        var inner: MemoryLenientAuthorizationMilestoneStore
        var cache: TTLCache<LenientAuthorizationMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientAuthorizationMilestoneStore, cache: TTLCache<LenientAuthorizationMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientAuthorizationMilestone? {
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

        func save(_ item: LenientAuthorizationMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientAuthorizationMilestone] {
            return inner.list()
        }
    }

    static func newCachedLenientAuthorizationMilestoneStore(_ inner: MemoryLenientAuthorizationMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientAuthorizationMilestoneStore {
        return CachedLenientAuthorizationMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient authorization milestones. Empty fields match all.
    final class LenientAuthorizationMilestoneQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientAuthorizationMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientAuthorizationMilestone]) -> [LenientAuthorizationMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientAuthorizationMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientAuthorizationMilestones(_ store: any LenientAuthorizationMilestoneStore, query: LenientAuthorizationMilestoneQuery) -> [LenientAuthorizationMilestone] {
        return query.apply(store.list())
    }
}
