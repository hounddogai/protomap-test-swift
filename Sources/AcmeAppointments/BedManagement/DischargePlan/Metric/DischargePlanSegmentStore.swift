import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan segments by code.
    protocol DischargePlanSegmentStore {
        func find(_ code: String) -> DischargePlanSegment?
        func save(_ item: DischargePlanSegment)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanSegmentStore: DischargePlanSegmentStore {
        var items: [String: DischargePlanSegment]
        var order: [String]

        init(items: [String: DischargePlanSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanSegment) {
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

        func list() -> [DischargePlanSegment] {
            var out: [DischargePlanSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanSegmentStore() -> any DischargePlanSegmentStore {
        return MemoryDischargePlanSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanSegmentStore: DischargePlanSegmentStore {
        var inner: MemoryDischargePlanSegmentStore
        var cache: TTLCache<DischargePlanSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanSegmentStore, cache: TTLCache<DischargePlanSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanSegment? {
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

        func save(_ item: DischargePlanSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanSegment] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanSegmentStore(_ inner: MemoryDischargePlanSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanSegmentStore {
        return CachedDischargePlanSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan segments. Empty fields match all.
    final class DischargePlanSegmentQuery {
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

        func matches(_ item: DischargePlanSegment) -> Bool {
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

        func apply(_ items: [DischargePlanSegment]) -> [DischargePlanSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanSegments(_ store: any DischargePlanSegmentStore, query: DischargePlanSegmentQuery) -> [DischargePlanSegment] {
        return query.apply(store.list())
    }
}
