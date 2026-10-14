import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer allocations by code.
    protocol TransferAllocationStore {
        func find(_ code: String) -> TransferAllocation?
        func save(_ item: TransferAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [TransferAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferAllocationStore: TransferAllocationStore {
        var items: [String: TransferAllocation]
        var order: [String]

        init(items: [String: TransferAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferAllocation) {
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

        func list() -> [TransferAllocation] {
            var out: [TransferAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferAllocationStore() -> any TransferAllocationStore {
        return MemoryTransferAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferAllocationStore: TransferAllocationStore {
        var inner: MemoryTransferAllocationStore
        var cache: TTLCache<TransferAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferAllocationStore, cache: TTLCache<TransferAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferAllocation? {
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

        func save(_ item: TransferAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferAllocation] {
            return inner.list()
        }
    }

    static func newCachedTransferAllocationStore(_ inner: MemoryTransferAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferAllocationStore {
        return CachedTransferAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer allocations. Empty fields match all.
    final class TransferAllocationQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TransferAllocation]) -> [TransferAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferAllocations(_ store: any TransferAllocationStore, query: TransferAllocationQuery) -> [TransferAllocation] {
        return query.apply(store.list())
    }
}
