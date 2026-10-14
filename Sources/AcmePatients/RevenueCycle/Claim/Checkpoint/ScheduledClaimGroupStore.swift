import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled claim groups by code.
    protocol ScheduledClaimGroupStore {
        func find(_ code: String) -> ScheduledClaimGroup?
        func save(_ item: ScheduledClaimGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledClaimGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledClaimGroupStore: ScheduledClaimGroupStore {
        var items: [String: ScheduledClaimGroup]
        var order: [String]

        init(items: [String: ScheduledClaimGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledClaimGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledClaimGroup) {
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

        func list() -> [ScheduledClaimGroup] {
            var out: [ScheduledClaimGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledClaimGroupStore() -> any ScheduledClaimGroupStore {
        return MemoryScheduledClaimGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledClaimGroupStore: ScheduledClaimGroupStore {
        var inner: MemoryScheduledClaimGroupStore
        var cache: TTLCache<ScheduledClaimGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledClaimGroupStore, cache: TTLCache<ScheduledClaimGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledClaimGroup? {
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

        func save(_ item: ScheduledClaimGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledClaimGroup] {
            return inner.list()
        }
    }

    static func newCachedScheduledClaimGroupStore(_ inner: MemoryScheduledClaimGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledClaimGroupStore {
        return CachedScheduledClaimGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled claim groups. Empty fields match all.
    final class ScheduledClaimGroupQuery {
        var category: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRetries: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledClaimGroup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledClaimGroup]) -> [ScheduledClaimGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledClaimGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledClaimGroups(_ store: any ScheduledClaimGroupStore, query: ScheduledClaimGroupQuery) -> [ScheduledClaimGroup] {
        return query.apply(store.list())
    }
}
