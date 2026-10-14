import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered care gap adjustments by code.
    protocol TieredCareGapAdjustmentStore {
        func find(_ code: String) -> TieredCareGapAdjustment?
        func save(_ item: TieredCareGapAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareGapAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareGapAdjustmentStore: TieredCareGapAdjustmentStore {
        var items: [String: TieredCareGapAdjustment]
        var order: [String]

        init(items: [String: TieredCareGapAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareGapAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareGapAdjustment) {
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

        func list() -> [TieredCareGapAdjustment] {
            var out: [TieredCareGapAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareGapAdjustmentStore() -> any TieredCareGapAdjustmentStore {
        return MemoryTieredCareGapAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareGapAdjustmentStore: TieredCareGapAdjustmentStore {
        var inner: MemoryTieredCareGapAdjustmentStore
        var cache: TTLCache<TieredCareGapAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareGapAdjustmentStore, cache: TTLCache<TieredCareGapAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareGapAdjustment? {
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

        func save(_ item: TieredCareGapAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareGapAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTieredCareGapAdjustmentStore(_ inner: MemoryTieredCareGapAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareGapAdjustmentStore {
        return CachedTieredCareGapAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care gap adjustments. Empty fields match all.
    final class TieredCareGapAdjustmentQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareGapAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareGapAdjustment]) -> [TieredCareGapAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareGapAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareGapAdjustments(_ store: any TieredCareGapAdjustmentStore, query: TieredCareGapAdjustmentQuery) -> [TieredCareGapAdjustment] {
        return query.apply(store.list())
    }
}
