import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched dispense overrides by code.
    protocol BatchedDispenseOverrideStore {
        func find(_ code: String) -> BatchedDispenseOverride?
        func save(_ item: BatchedDispenseOverride)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDispenseOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDispenseOverrideStore: BatchedDispenseOverrideStore {
        var items: [String: BatchedDispenseOverride]
        var order: [String]

        init(items: [String: BatchedDispenseOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDispenseOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDispenseOverride) {
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

        func list() -> [BatchedDispenseOverride] {
            var out: [BatchedDispenseOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDispenseOverrideStore() -> any BatchedDispenseOverrideStore {
        return MemoryBatchedDispenseOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDispenseOverrideStore: BatchedDispenseOverrideStore {
        var inner: MemoryBatchedDispenseOverrideStore
        var cache: TTLCache<BatchedDispenseOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDispenseOverrideStore, cache: TTLCache<BatchedDispenseOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDispenseOverride? {
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

        func save(_ item: BatchedDispenseOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDispenseOverride] {
            return inner.list()
        }
    }

    static func newCachedBatchedDispenseOverrideStore(_ inner: MemoryBatchedDispenseOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDispenseOverrideStore {
        return CachedBatchedDispenseOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched dispense overrides. Empty fields match all.
    final class BatchedDispenseOverrideQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDispenseOverride) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDispenseOverride]) -> [BatchedDispenseOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDispenseOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDispenseOverrides(_ store: any BatchedDispenseOverrideStore, query: BatchedDispenseOverrideQuery) -> [BatchedDispenseOverride] {
        return query.apply(store.list())
    }
}
