import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix allocations by code.
    protocol SkillMixAllocationStore {
        func find(_ code: String) -> SkillMixAllocation?
        func save(_ item: SkillMixAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixAllocationStore: SkillMixAllocationStore {
        var items: [String: SkillMixAllocation]
        var order: [String]

        init(items: [String: SkillMixAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixAllocation) {
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

        func list() -> [SkillMixAllocation] {
            var out: [SkillMixAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixAllocationStore() -> any SkillMixAllocationStore {
        return MemorySkillMixAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixAllocationStore: SkillMixAllocationStore {
        var inner: MemorySkillMixAllocationStore
        var cache: TTLCache<SkillMixAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixAllocationStore, cache: TTLCache<SkillMixAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixAllocation? {
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

        func save(_ item: SkillMixAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixAllocation] {
            return inner.list()
        }
    }

    static func newCachedSkillMixAllocationStore(_ inner: MemorySkillMixAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixAllocationStore {
        return CachedSkillMixAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix allocations. Empty fields match all.
    final class SkillMixAllocationQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixAllocation]) -> [SkillMixAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixAllocations(_ store: any SkillMixAllocationStore, query: SkillMixAllocationQuery) -> [SkillMixAllocation] {
        return query.apply(store.list())
    }
}
