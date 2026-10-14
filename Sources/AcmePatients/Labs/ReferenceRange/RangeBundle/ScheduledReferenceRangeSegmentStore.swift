import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled reference range segments by code.
    protocol ScheduledReferenceRangeSegmentStore {
        func find(_ code: String) -> ScheduledReferenceRangeSegment?
        func save(_ item: ScheduledReferenceRangeSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReferenceRangeSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReferenceRangeSegmentStore: ScheduledReferenceRangeSegmentStore {
        var items: [String: ScheduledReferenceRangeSegment]
        var order: [String]

        init(items: [String: ScheduledReferenceRangeSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReferenceRangeSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReferenceRangeSegment) {
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

        func list() -> [ScheduledReferenceRangeSegment] {
            var out: [ScheduledReferenceRangeSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReferenceRangeSegmentStore() -> any ScheduledReferenceRangeSegmentStore {
        return MemoryScheduledReferenceRangeSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReferenceRangeSegmentStore: ScheduledReferenceRangeSegmentStore {
        var inner: MemoryScheduledReferenceRangeSegmentStore
        var cache: TTLCache<ScheduledReferenceRangeSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReferenceRangeSegmentStore, cache: TTLCache<ScheduledReferenceRangeSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReferenceRangeSegment? {
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

        func save(_ item: ScheduledReferenceRangeSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReferenceRangeSegment] {
            return inner.list()
        }
    }

    static func newCachedScheduledReferenceRangeSegmentStore(_ inner: MemoryScheduledReferenceRangeSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReferenceRangeSegmentStore {
        return CachedScheduledReferenceRangeSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled reference range segments. Empty fields match all.
    final class ScheduledReferenceRangeSegmentQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReferenceRangeSegment) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReferenceRangeSegment]) -> [ScheduledReferenceRangeSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReferenceRangeSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReferenceRangeSegments(_ store: any ScheduledReferenceRangeSegmentStore, query: ScheduledReferenceRangeSegmentQuery) -> [ScheduledReferenceRangeSegment] {
        return query.apply(store.list())
    }
}
