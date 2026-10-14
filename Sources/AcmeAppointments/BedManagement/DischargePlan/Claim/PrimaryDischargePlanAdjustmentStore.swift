import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary discharge plan adjustments by code.
    protocol PrimaryDischargePlanAdjustmentStore {
        func find(_ code: String) -> PrimaryDischargePlanAdjustment?
        func save(_ item: PrimaryDischargePlanAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDischargePlanAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDischargePlanAdjustmentStore: PrimaryDischargePlanAdjustmentStore {
        var items: [String: PrimaryDischargePlanAdjustment]
        var order: [String]

        init(items: [String: PrimaryDischargePlanAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDischargePlanAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDischargePlanAdjustment) {
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

        func list() -> [PrimaryDischargePlanAdjustment] {
            var out: [PrimaryDischargePlanAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDischargePlanAdjustmentStore() -> any PrimaryDischargePlanAdjustmentStore {
        return MemoryPrimaryDischargePlanAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDischargePlanAdjustmentStore: PrimaryDischargePlanAdjustmentStore {
        var inner: MemoryPrimaryDischargePlanAdjustmentStore
        var cache: TTLCache<PrimaryDischargePlanAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDischargePlanAdjustmentStore, cache: TTLCache<PrimaryDischargePlanAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDischargePlanAdjustment? {
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

        func save(_ item: PrimaryDischargePlanAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDischargePlanAdjustment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDischargePlanAdjustmentStore(_ inner: MemoryPrimaryDischargePlanAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDischargePlanAdjustmentStore {
        return CachedPrimaryDischargePlanAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary discharge plan adjustments. Empty fields match all.
    final class PrimaryDischargePlanAdjustmentQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryDischargePlanAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryDischargePlanAdjustment]) -> [PrimaryDischargePlanAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDischargePlanAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDischargePlanAdjustments(_ store: any PrimaryDischargePlanAdjustmentStore, query: PrimaryDischargePlanAdjustmentQuery) -> [PrimaryDischargePlanAdjustment] {
        return query.apply(store.list())
    }
}
