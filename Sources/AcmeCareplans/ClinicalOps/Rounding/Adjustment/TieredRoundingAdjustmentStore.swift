import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered rounding adjustments by code.
    protocol TieredRoundingAdjustmentStore {
        func find(_ code: String) -> TieredRoundingAdjustment?
        func save(_ item: TieredRoundingAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRoundingAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRoundingAdjustmentStore: TieredRoundingAdjustmentStore {
        var items: [String: TieredRoundingAdjustment]
        var order: [String]

        init(items: [String: TieredRoundingAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRoundingAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRoundingAdjustment) {
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

        func list() -> [TieredRoundingAdjustment] {
            var out: [TieredRoundingAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRoundingAdjustmentStore() -> any TieredRoundingAdjustmentStore {
        return MemoryTieredRoundingAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRoundingAdjustmentStore: TieredRoundingAdjustmentStore {
        var inner: MemoryTieredRoundingAdjustmentStore
        var cache: TTLCache<TieredRoundingAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRoundingAdjustmentStore, cache: TTLCache<TieredRoundingAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRoundingAdjustment? {
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

        func save(_ item: TieredRoundingAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRoundingAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTieredRoundingAdjustmentStore(_ inner: MemoryTieredRoundingAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRoundingAdjustmentStore {
        return CachedTieredRoundingAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered rounding adjustments. Empty fields match all.
    final class TieredRoundingAdjustmentQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRoundingAdjustment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRoundingAdjustment]) -> [TieredRoundingAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRoundingAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRoundingAdjustments(_ store: any TieredRoundingAdjustmentStore, query: TieredRoundingAdjustmentQuery) -> [TieredRoundingAdjustment] {
        return query.apply(store.list())
    }
}
