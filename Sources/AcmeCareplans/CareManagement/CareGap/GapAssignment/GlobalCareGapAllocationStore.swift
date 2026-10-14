import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global care gap allocations by code.
    protocol GlobalCareGapAllocationStore {
        func find(_ code: String) -> GlobalCareGapAllocation?
        func save(_ item: GlobalCareGapAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareGapAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareGapAllocationStore: GlobalCareGapAllocationStore {
        var items: [String: GlobalCareGapAllocation]
        var order: [String]

        init(items: [String: GlobalCareGapAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareGapAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareGapAllocation) {
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

        func list() -> [GlobalCareGapAllocation] {
            var out: [GlobalCareGapAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareGapAllocationStore() -> any GlobalCareGapAllocationStore {
        return MemoryGlobalCareGapAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareGapAllocationStore: GlobalCareGapAllocationStore {
        var inner: MemoryGlobalCareGapAllocationStore
        var cache: TTLCache<GlobalCareGapAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareGapAllocationStore, cache: TTLCache<GlobalCareGapAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareGapAllocation? {
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

        func save(_ item: GlobalCareGapAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareGapAllocation] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareGapAllocationStore(_ inner: MemoryGlobalCareGapAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareGapAllocationStore {
        return CachedGlobalCareGapAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care gap allocations. Empty fields match all.
    final class GlobalCareGapAllocationQuery {
        var channel: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCareGapAllocation) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [GlobalCareGapAllocation]) -> [GlobalCareGapAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareGapAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareGapAllocations(_ store: any GlobalCareGapAllocationStore, query: GlobalCareGapAllocationQuery) -> [GlobalCareGapAllocation] {
        return query.apply(store.list())
    }
}
