import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction groups by code.
    protocol InteractionGroupStore {
        func find(_ code: String) -> InteractionGroup?
        func save(_ item: InteractionGroup)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionGroupStore: InteractionGroupStore {
        var items: [String: InteractionGroup]
        var order: [String]

        init(items: [String: InteractionGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionGroup) {
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

        func list() -> [InteractionGroup] {
            var out: [InteractionGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionGroupStore() -> any InteractionGroupStore {
        return MemoryInteractionGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionGroupStore: InteractionGroupStore {
        var inner: MemoryInteractionGroupStore
        var cache: TTLCache<InteractionGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionGroupStore, cache: TTLCache<InteractionGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionGroup? {
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

        func save(_ item: InteractionGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionGroup] {
            return inner.list()
        }
    }

    static func newCachedInteractionGroupStore(_ inner: MemoryInteractionGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionGroupStore {
        return CachedInteractionGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction groups. Empty fields match all.
    final class InteractionGroupQuery {
        var region: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionGroup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionGroup]) -> [InteractionGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionGroups(_ store: any InteractionGroupStore, query: InteractionGroupQuery) -> [InteractionGroup] {
        return query.apply(store.list())
    }
}
