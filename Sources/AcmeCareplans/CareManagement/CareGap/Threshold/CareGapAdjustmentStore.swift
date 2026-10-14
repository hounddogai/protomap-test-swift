import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap adjustments by code.
    protocol CareGapAdjustmentStore {
        func find(_ code: String) -> CareGapAdjustment?
        func save(_ item: CareGapAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapAdjustmentStore: CareGapAdjustmentStore {
        var items: [String: CareGapAdjustment]
        var order: [String]

        init(items: [String: CareGapAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapAdjustment) {
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

        func list() -> [CareGapAdjustment] {
            var out: [CareGapAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapAdjustmentStore() -> any CareGapAdjustmentStore {
        return MemoryCareGapAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapAdjustmentStore: CareGapAdjustmentStore {
        var inner: MemoryCareGapAdjustmentStore
        var cache: TTLCache<CareGapAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapAdjustmentStore, cache: TTLCache<CareGapAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapAdjustment? {
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

        func save(_ item: CareGapAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCareGapAdjustmentStore(_ inner: MemoryCareGapAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapAdjustmentStore {
        return CachedCareGapAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap adjustments. Empty fields match all.
    final class CareGapAdjustmentQuery {
        var source: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVersion: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapAdjustment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [CareGapAdjustment]) -> [CareGapAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapAdjustments(_ store: any CareGapAdjustmentStore, query: CareGapAdjustmentQuery) -> [CareGapAdjustment] {
        return query.apply(store.list())
    }
}
