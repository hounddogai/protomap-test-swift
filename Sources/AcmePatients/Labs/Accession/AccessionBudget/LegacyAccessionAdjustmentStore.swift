import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy accession adjustments by code.
    protocol LegacyAccessionAdjustmentStore {
        func find(_ code: String) -> LegacyAccessionAdjustment?
        func save(_ item: LegacyAccessionAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAccessionAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAccessionAdjustmentStore: LegacyAccessionAdjustmentStore {
        var items: [String: LegacyAccessionAdjustment]
        var order: [String]

        init(items: [String: LegacyAccessionAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAccessionAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAccessionAdjustment) {
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

        func list() -> [LegacyAccessionAdjustment] {
            var out: [LegacyAccessionAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAccessionAdjustmentStore() -> any LegacyAccessionAdjustmentStore {
        return MemoryLegacyAccessionAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAccessionAdjustmentStore: LegacyAccessionAdjustmentStore {
        var inner: MemoryLegacyAccessionAdjustmentStore
        var cache: TTLCache<LegacyAccessionAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAccessionAdjustmentStore, cache: TTLCache<LegacyAccessionAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAccessionAdjustment? {
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

        func save(_ item: LegacyAccessionAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAccessionAdjustment] {
            return inner.list()
        }
    }

    static func newCachedLegacyAccessionAdjustmentStore(_ inner: MemoryLegacyAccessionAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAccessionAdjustmentStore {
        return CachedLegacyAccessionAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy accession adjustments. Empty fields match all.
    final class LegacyAccessionAdjustmentQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAccessionAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAccessionAdjustment]) -> [LegacyAccessionAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAccessionAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAccessionAdjustments(_ store: any LegacyAccessionAdjustmentStore, query: LegacyAccessionAdjustmentQuery) -> [LegacyAccessionAdjustment] {
        return query.apply(store.list())
    }
}
