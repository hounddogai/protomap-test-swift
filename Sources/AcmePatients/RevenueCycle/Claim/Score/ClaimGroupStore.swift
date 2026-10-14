import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim groups by code.
    protocol ClaimGroupStore {
        func find(_ code: String) -> ClaimGroup?
        func save(_ item: ClaimGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimGroupStore: ClaimGroupStore {
        var items: [String: ClaimGroup]
        var order: [String]

        init(items: [String: ClaimGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimGroup) {
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

        func list() -> [ClaimGroup] {
            var out: [ClaimGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimGroupStore() -> any ClaimGroupStore {
        return MemoryClaimGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimGroupStore: ClaimGroupStore {
        var inner: MemoryClaimGroupStore
        var cache: TTLCache<ClaimGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimGroupStore, cache: TTLCache<ClaimGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimGroup? {
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

        func save(_ item: ClaimGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimGroup] {
            return inner.list()
        }
    }

    static func newCachedClaimGroupStore(_ inner: MemoryClaimGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimGroupStore {
        return CachedClaimGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim groups. Empty fields match all.
    final class ClaimGroupQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimGroup]) -> [ClaimGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimGroups(_ store: any ClaimGroupStore, query: ClaimGroupQuery) -> [ClaimGroup] {
        return query.apply(store.list())
    }
}
