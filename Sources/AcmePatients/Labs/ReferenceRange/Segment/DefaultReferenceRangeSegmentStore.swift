import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default reference range segments by code.
    protocol DefaultReferenceRangeSegmentStore {
        func find(_ code: String) -> DefaultReferenceRangeSegment?
        func save(_ item: DefaultReferenceRangeSegment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultReferenceRangeSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultReferenceRangeSegmentStore: DefaultReferenceRangeSegmentStore {
        var items: [String: DefaultReferenceRangeSegment]
        var order: [String]

        init(items: [String: DefaultReferenceRangeSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultReferenceRangeSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultReferenceRangeSegment) {
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

        func list() -> [DefaultReferenceRangeSegment] {
            var out: [DefaultReferenceRangeSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultReferenceRangeSegmentStore() -> any DefaultReferenceRangeSegmentStore {
        return MemoryDefaultReferenceRangeSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultReferenceRangeSegmentStore: DefaultReferenceRangeSegmentStore {
        var inner: MemoryDefaultReferenceRangeSegmentStore
        var cache: TTLCache<DefaultReferenceRangeSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultReferenceRangeSegmentStore, cache: TTLCache<DefaultReferenceRangeSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultReferenceRangeSegment? {
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

        func save(_ item: DefaultReferenceRangeSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultReferenceRangeSegment] {
            return inner.list()
        }
    }

    static func newCachedDefaultReferenceRangeSegmentStore(_ inner: MemoryDefaultReferenceRangeSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultReferenceRangeSegmentStore {
        return CachedDefaultReferenceRangeSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default reference range segments. Empty fields match all.
    final class DefaultReferenceRangeSegmentQuery {
        var facility: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultReferenceRangeSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultReferenceRangeSegment]) -> [DefaultReferenceRangeSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultReferenceRangeSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultReferenceRangeSegments(_ store: any DefaultReferenceRangeSegmentStore, query: DefaultReferenceRangeSegmentQuery) -> [DefaultReferenceRangeSegment] {
        return query.apply(store.list())
    }
}
