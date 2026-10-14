import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy discharge plan segments by code.
    protocol LegacyDischargePlanSegmentStore {
        func find(_ code: String) -> LegacyDischargePlanSegment?
        func save(_ item: LegacyDischargePlanSegment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDischargePlanSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDischargePlanSegmentStore: LegacyDischargePlanSegmentStore {
        var items: [String: LegacyDischargePlanSegment]
        var order: [String]

        init(items: [String: LegacyDischargePlanSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDischargePlanSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDischargePlanSegment) {
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

        func list() -> [LegacyDischargePlanSegment] {
            var out: [LegacyDischargePlanSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDischargePlanSegmentStore() -> any LegacyDischargePlanSegmentStore {
        return MemoryLegacyDischargePlanSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDischargePlanSegmentStore: LegacyDischargePlanSegmentStore {
        var inner: MemoryLegacyDischargePlanSegmentStore
        var cache: TTLCache<LegacyDischargePlanSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDischargePlanSegmentStore, cache: TTLCache<LegacyDischargePlanSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDischargePlanSegment? {
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

        func save(_ item: LegacyDischargePlanSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDischargePlanSegment] {
            return inner.list()
        }
    }

    static func newCachedLegacyDischargePlanSegmentStore(_ inner: MemoryLegacyDischargePlanSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDischargePlanSegmentStore {
        return CachedLegacyDischargePlanSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy discharge plan segments. Empty fields match all.
    final class LegacyDischargePlanSegmentQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDischargePlanSegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDischargePlanSegment]) -> [LegacyDischargePlanSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDischargePlanSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDischargePlanSegments(_ store: any LegacyDischargePlanSegmentStore, query: LegacyDischargePlanSegmentQuery) -> [LegacyDischargePlanSegment] {
        return query.apply(store.list())
    }
}
