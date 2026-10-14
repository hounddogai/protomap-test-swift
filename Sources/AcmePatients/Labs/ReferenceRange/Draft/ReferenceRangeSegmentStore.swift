import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range segments by code.
    protocol ReferenceRangeSegmentStore {
        func find(_ code: String) -> ReferenceRangeSegment?
        func save(_ item: ReferenceRangeSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeSegmentStore: ReferenceRangeSegmentStore {
        var items: [String: ReferenceRangeSegment]
        var order: [String]

        init(items: [String: ReferenceRangeSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeSegment) {
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

        func list() -> [ReferenceRangeSegment] {
            var out: [ReferenceRangeSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeSegmentStore() -> any ReferenceRangeSegmentStore {
        return MemoryReferenceRangeSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeSegmentStore: ReferenceRangeSegmentStore {
        var inner: MemoryReferenceRangeSegmentStore
        var cache: TTLCache<ReferenceRangeSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeSegmentStore, cache: TTLCache<ReferenceRangeSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeSegment? {
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

        func save(_ item: ReferenceRangeSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeSegment] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeSegmentStore(_ inner: MemoryReferenceRangeSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeSegmentStore {
        return CachedReferenceRangeSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range segments. Empty fields match all.
    final class ReferenceRangeSegmentQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeSegment]) -> [ReferenceRangeSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeSegments(_ store: any ReferenceRangeSegmentStore, query: ReferenceRangeSegmentQuery) -> [ReferenceRangeSegment] {
        return query.apply(store.list())
    }
}
