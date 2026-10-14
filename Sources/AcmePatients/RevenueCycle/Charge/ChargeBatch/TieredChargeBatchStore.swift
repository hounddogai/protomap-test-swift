import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered charge batches by code.
    protocol TieredChargeBatchStore {
        func find(_ code: String) -> TieredChargeBatch?
        func save(_ item: TieredChargeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [TieredChargeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredChargeBatchStore: TieredChargeBatchStore {
        var items: [String: TieredChargeBatch]
        var order: [String]

        init(items: [String: TieredChargeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredChargeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredChargeBatch) {
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

        func list() -> [TieredChargeBatch] {
            var out: [TieredChargeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredChargeBatchStore() -> any TieredChargeBatchStore {
        return MemoryTieredChargeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredChargeBatchStore: TieredChargeBatchStore {
        var inner: MemoryTieredChargeBatchStore
        var cache: TTLCache<TieredChargeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredChargeBatchStore, cache: TTLCache<TieredChargeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredChargeBatch? {
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

        func save(_ item: TieredChargeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredChargeBatch] {
            return inner.list()
        }
    }

    static func newCachedTieredChargeBatchStore(_ inner: MemoryTieredChargeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredChargeBatchStore {
        return CachedTieredChargeBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered charge batches. Empty fields match all.
    final class TieredChargeBatchQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredChargeBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredChargeBatch]) -> [TieredChargeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredChargeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredChargeBatches(_ store: any TieredChargeBatchStore, query: TieredChargeBatchQuery) -> [TieredChargeBatch] {
        return query.apply(store.list())
    }
}
