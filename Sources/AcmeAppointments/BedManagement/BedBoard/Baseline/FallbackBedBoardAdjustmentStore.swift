import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback bed board adjustments by code.
    protocol FallbackBedBoardAdjustmentStore {
        func find(_ code: String) -> FallbackBedBoardAdjustment?
        func save(_ item: FallbackBedBoardAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackBedBoardAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackBedBoardAdjustmentStore: FallbackBedBoardAdjustmentStore {
        var items: [String: FallbackBedBoardAdjustment]
        var order: [String]

        init(items: [String: FallbackBedBoardAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackBedBoardAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackBedBoardAdjustment) {
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

        func list() -> [FallbackBedBoardAdjustment] {
            var out: [FallbackBedBoardAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackBedBoardAdjustmentStore() -> any FallbackBedBoardAdjustmentStore {
        return MemoryFallbackBedBoardAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackBedBoardAdjustmentStore: FallbackBedBoardAdjustmentStore {
        var inner: MemoryFallbackBedBoardAdjustmentStore
        var cache: TTLCache<FallbackBedBoardAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackBedBoardAdjustmentStore, cache: TTLCache<FallbackBedBoardAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackBedBoardAdjustment? {
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

        func save(_ item: FallbackBedBoardAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackBedBoardAdjustment] {
            return inner.list()
        }
    }

    static func newCachedFallbackBedBoardAdjustmentStore(_ inner: MemoryFallbackBedBoardAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackBedBoardAdjustmentStore {
        return CachedFallbackBedBoardAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback bed board adjustments. Empty fields match all.
    final class FallbackBedBoardAdjustmentQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackBedBoardAdjustment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackBedBoardAdjustment]) -> [FallbackBedBoardAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackBedBoardAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackBedBoardAdjustments(_ store: any FallbackBedBoardAdjustmentStore, query: FallbackBedBoardAdjustmentQuery) -> [FallbackBedBoardAdjustment] {
        return query.apply(store.list())
    }
}
