import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered worklist adjustments by code.
    protocol TieredWorklistAdjustmentStore {
        func find(_ code: String) -> TieredWorklistAdjustment?
        func save(_ item: TieredWorklistAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredWorklistAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredWorklistAdjustmentStore: TieredWorklistAdjustmentStore {
        var items: [String: TieredWorklistAdjustment]
        var order: [String]

        init(items: [String: TieredWorklistAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredWorklistAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredWorklistAdjustment) {
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

        func list() -> [TieredWorklistAdjustment] {
            var out: [TieredWorklistAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredWorklistAdjustmentStore() -> any TieredWorklistAdjustmentStore {
        return MemoryTieredWorklistAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredWorklistAdjustmentStore: TieredWorklistAdjustmentStore {
        var inner: MemoryTieredWorklistAdjustmentStore
        var cache: TTLCache<TieredWorklistAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredWorklistAdjustmentStore, cache: TTLCache<TieredWorklistAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredWorklistAdjustment? {
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

        func save(_ item: TieredWorklistAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredWorklistAdjustment] {
            return inner.list()
        }
    }

    static func newCachedTieredWorklistAdjustmentStore(_ inner: MemoryTieredWorklistAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredWorklistAdjustmentStore {
        return CachedTieredWorklistAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered worklist adjustments. Empty fields match all.
    final class TieredWorklistAdjustmentQuery {
        var country: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMargin: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredWorklistAdjustment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredWorklistAdjustment]) -> [TieredWorklistAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredWorklistAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredWorklistAdjustments(_ store: any TieredWorklistAdjustmentStore, query: TieredWorklistAdjustmentQuery) -> [TieredWorklistAdjustment] {
        return query.apply(store.list())
    }
}
