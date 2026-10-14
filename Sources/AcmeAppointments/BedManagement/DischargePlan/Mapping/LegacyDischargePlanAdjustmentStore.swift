import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy discharge plan adjustments by code.
    protocol LegacyDischargePlanAdjustmentStore {
        func find(_ code: String) -> LegacyDischargePlanAdjustment?
        func save(_ item: LegacyDischargePlanAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDischargePlanAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDischargePlanAdjustmentStore: LegacyDischargePlanAdjustmentStore {
        var items: [String: LegacyDischargePlanAdjustment]
        var order: [String]

        init(items: [String: LegacyDischargePlanAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDischargePlanAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDischargePlanAdjustment) {
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

        func list() -> [LegacyDischargePlanAdjustment] {
            var out: [LegacyDischargePlanAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDischargePlanAdjustmentStore() -> any LegacyDischargePlanAdjustmentStore {
        return MemoryLegacyDischargePlanAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDischargePlanAdjustmentStore: LegacyDischargePlanAdjustmentStore {
        var inner: MemoryLegacyDischargePlanAdjustmentStore
        var cache: TTLCache<LegacyDischargePlanAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDischargePlanAdjustmentStore, cache: TTLCache<LegacyDischargePlanAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDischargePlanAdjustment? {
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

        func save(_ item: LegacyDischargePlanAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDischargePlanAdjustment] {
            return inner.list()
        }
    }

    static func newCachedLegacyDischargePlanAdjustmentStore(_ inner: MemoryLegacyDischargePlanAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDischargePlanAdjustmentStore {
        return CachedLegacyDischargePlanAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy discharge plan adjustments. Empty fields match all.
    final class LegacyDischargePlanAdjustmentQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDischargePlanAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDischargePlanAdjustment]) -> [LegacyDischargePlanAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDischargePlanAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDischargePlanAdjustments(_ store: any LegacyDischargePlanAdjustmentStore, query: LegacyDischargePlanAdjustmentQuery) -> [LegacyDischargePlanAdjustment] {
        return query.apply(store.list())
    }
}
