import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient transfer allocations by code.
    protocol LenientTransferAllocationStore {
        func find(_ code: String) -> LenientTransferAllocation?
        func save(_ item: LenientTransferAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [LenientTransferAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientTransferAllocationStore: LenientTransferAllocationStore {
        var items: [String: LenientTransferAllocation]
        var order: [String]

        init(items: [String: LenientTransferAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientTransferAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientTransferAllocation) {
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

        func list() -> [LenientTransferAllocation] {
            var out: [LenientTransferAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientTransferAllocationStore() -> any LenientTransferAllocationStore {
        return MemoryLenientTransferAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientTransferAllocationStore: LenientTransferAllocationStore {
        var inner: MemoryLenientTransferAllocationStore
        var cache: TTLCache<LenientTransferAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientTransferAllocationStore, cache: TTLCache<LenientTransferAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientTransferAllocation? {
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

        func save(_ item: LenientTransferAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientTransferAllocation] {
            return inner.list()
        }
    }

    static func newCachedLenientTransferAllocationStore(_ inner: MemoryLenientTransferAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientTransferAllocationStore {
        return CachedLenientTransferAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient transfer allocations. Empty fields match all.
    final class LenientTransferAllocationQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientTransferAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientTransferAllocation]) -> [LenientTransferAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientTransferAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientTransferAllocations(_ store: any LenientTransferAllocationStore, query: LenientTransferAllocationQuery) -> [LenientTransferAllocation] {
        return query.apply(store.list())
    }
}
