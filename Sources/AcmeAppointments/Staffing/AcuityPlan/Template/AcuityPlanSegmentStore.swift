import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan segments by code.
    protocol AcuityPlanSegmentStore {
        func find(_ code: String) -> AcuityPlanSegment?
        func save(_ item: AcuityPlanSegment)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanSegmentStore: AcuityPlanSegmentStore {
        var items: [String: AcuityPlanSegment]
        var order: [String]

        init(items: [String: AcuityPlanSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanSegment) {
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

        func list() -> [AcuityPlanSegment] {
            var out: [AcuityPlanSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanSegmentStore() -> any AcuityPlanSegmentStore {
        return MemoryAcuityPlanSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanSegmentStore: AcuityPlanSegmentStore {
        var inner: MemoryAcuityPlanSegmentStore
        var cache: TTLCache<AcuityPlanSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanSegmentStore, cache: TTLCache<AcuityPlanSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanSegment? {
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

        func save(_ item: AcuityPlanSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanSegment] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanSegmentStore(_ inner: MemoryAcuityPlanSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanSegmentStore {
        return CachedAcuityPlanSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan segments. Empty fields match all.
    final class AcuityPlanSegmentQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AcuityPlanSegment]) -> [AcuityPlanSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanSegments(_ store: any AcuityPlanSegmentStore, query: AcuityPlanSegmentQuery) -> [AcuityPlanSegment] {
        return query.apply(store.list())
    }
}
