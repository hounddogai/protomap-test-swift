import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default language allocations by code.
    protocol DefaultLanguageAllocationStore {
        func find(_ code: String) -> DefaultLanguageAllocation?
        func save(_ item: DefaultLanguageAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultLanguageAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultLanguageAllocationStore: DefaultLanguageAllocationStore {
        var items: [String: DefaultLanguageAllocation]
        var order: [String]

        init(items: [String: DefaultLanguageAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultLanguageAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultLanguageAllocation) {
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

        func list() -> [DefaultLanguageAllocation] {
            var out: [DefaultLanguageAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultLanguageAllocationStore() -> any DefaultLanguageAllocationStore {
        return MemoryDefaultLanguageAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultLanguageAllocationStore: DefaultLanguageAllocationStore {
        var inner: MemoryDefaultLanguageAllocationStore
        var cache: TTLCache<DefaultLanguageAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultLanguageAllocationStore, cache: TTLCache<DefaultLanguageAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultLanguageAllocation? {
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

        func save(_ item: DefaultLanguageAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultLanguageAllocation] {
            return inner.list()
        }
    }

    static func newCachedDefaultLanguageAllocationStore(_ inner: MemoryDefaultLanguageAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultLanguageAllocationStore {
        return CachedDefaultLanguageAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default language allocations. Empty fields match all.
    final class DefaultLanguageAllocationQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultLanguageAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultLanguageAllocation]) -> [DefaultLanguageAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultLanguageAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultLanguageAllocations(_ store: any DefaultLanguageAllocationStore, query: DefaultLanguageAllocationQuery) -> [DefaultLanguageAllocation] {
        return query.apply(store.list())
    }
}
