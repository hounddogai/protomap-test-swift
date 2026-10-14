import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan adjustments by code.
    protocol DischargePlanAdjustmentStore {
        func find(_ code: String) -> DischargePlanAdjustment?
        func save(_ item: DischargePlanAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanAdjustmentStore: DischargePlanAdjustmentStore {
        var items: [String: DischargePlanAdjustment]
        var order: [String]

        init(items: [String: DischargePlanAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanAdjustment) {
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

        func list() -> [DischargePlanAdjustment] {
            var out: [DischargePlanAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanAdjustmentStore() -> any DischargePlanAdjustmentStore {
        return MemoryDischargePlanAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanAdjustmentStore: DischargePlanAdjustmentStore {
        var inner: MemoryDischargePlanAdjustmentStore
        var cache: TTLCache<DischargePlanAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanAdjustmentStore, cache: TTLCache<DischargePlanAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanAdjustment? {
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

        func save(_ item: DischargePlanAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanAdjustment] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanAdjustmentStore(_ inner: MemoryDischargePlanAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanAdjustmentStore {
        return CachedDischargePlanAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan adjustments. Empty fields match all.
    final class DischargePlanAdjustmentQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanAdjustment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanAdjustment]) -> [DischargePlanAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanAdjustments(_ store: any DischargePlanAdjustmentStore, query: DischargePlanAdjustmentQuery) -> [DischargePlanAdjustment] {
        return query.apply(store.list())
    }
}
