import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending charge batches by code.
    protocol PendingChargeBatchStore {
        func find(_ code: String) -> PendingChargeBatch?
        func save(_ item: PendingChargeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PendingChargeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingChargeBatchStore: PendingChargeBatchStore {
        var items: [String: PendingChargeBatch]
        var order: [String]

        init(items: [String: PendingChargeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingChargeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingChargeBatch) {
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

        func list() -> [PendingChargeBatch] {
            var out: [PendingChargeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingChargeBatchStore() -> any PendingChargeBatchStore {
        return MemoryPendingChargeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingChargeBatchStore: PendingChargeBatchStore {
        var inner: MemoryPendingChargeBatchStore
        var cache: TTLCache<PendingChargeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingChargeBatchStore, cache: TTLCache<PendingChargeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingChargeBatch? {
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

        func save(_ item: PendingChargeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingChargeBatch] {
            return inner.list()
        }
    }

    static func newCachedPendingChargeBatchStore(_ inner: MemoryPendingChargeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingChargeBatchStore {
        return CachedPendingChargeBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending charge batches. Empty fields match all.
    final class PendingChargeBatchQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingChargeBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingChargeBatch]) -> [PendingChargeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingChargeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingChargeBatches(_ store: any PendingChargeBatchStore, query: PendingChargeBatchQuery) -> [PendingChargeBatch] {
        return query.apply(store.list())
    }
}
