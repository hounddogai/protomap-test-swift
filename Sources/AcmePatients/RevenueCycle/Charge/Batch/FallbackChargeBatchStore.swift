import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback charge batches by code.
    protocol FallbackChargeBatchStore {
        func find(_ code: String) -> FallbackChargeBatch?
        func save(_ item: FallbackChargeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackChargeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackChargeBatchStore: FallbackChargeBatchStore {
        var items: [String: FallbackChargeBatch]
        var order: [String]

        init(items: [String: FallbackChargeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackChargeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackChargeBatch) {
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

        func list() -> [FallbackChargeBatch] {
            var out: [FallbackChargeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackChargeBatchStore() -> any FallbackChargeBatchStore {
        return MemoryFallbackChargeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackChargeBatchStore: FallbackChargeBatchStore {
        var inner: MemoryFallbackChargeBatchStore
        var cache: TTLCache<FallbackChargeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackChargeBatchStore, cache: TTLCache<FallbackChargeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackChargeBatch? {
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

        func save(_ item: FallbackChargeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackChargeBatch] {
            return inner.list()
        }
    }

    static func newCachedFallbackChargeBatchStore(_ inner: MemoryFallbackChargeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackChargeBatchStore {
        return CachedFallbackChargeBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback charge batches. Empty fields match all.
    final class FallbackChargeBatchQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackChargeBatch) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [FallbackChargeBatch]) -> [FallbackChargeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackChargeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackChargeBatches(_ store: any FallbackChargeBatchStore, query: FallbackChargeBatchQuery) -> [FallbackChargeBatch] {
        return query.apply(store.list())
    }
}
