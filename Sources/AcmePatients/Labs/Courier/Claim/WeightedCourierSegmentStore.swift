import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted courier segments by code.
    protocol WeightedCourierSegmentStore {
        func find(_ code: String) -> WeightedCourierSegment?
        func save(_ item: WeightedCourierSegment)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCourierSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCourierSegmentStore: WeightedCourierSegmentStore {
        var items: [String: WeightedCourierSegment]
        var order: [String]

        init(items: [String: WeightedCourierSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCourierSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCourierSegment) {
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

        func list() -> [WeightedCourierSegment] {
            var out: [WeightedCourierSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCourierSegmentStore() -> any WeightedCourierSegmentStore {
        return MemoryWeightedCourierSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCourierSegmentStore: WeightedCourierSegmentStore {
        var inner: MemoryWeightedCourierSegmentStore
        var cache: TTLCache<WeightedCourierSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCourierSegmentStore, cache: TTLCache<WeightedCourierSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCourierSegment? {
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

        func save(_ item: WeightedCourierSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCourierSegment] {
            return inner.list()
        }
    }

    static func newCachedWeightedCourierSegmentStore(_ inner: MemoryWeightedCourierSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCourierSegmentStore {
        return CachedWeightedCourierSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted courier segments. Empty fields match all.
    final class WeightedCourierSegmentQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCourierSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedCourierSegment]) -> [WeightedCourierSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCourierSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCourierSegments(_ store: any WeightedCourierSegmentStore, query: WeightedCourierSegmentQuery) -> [WeightedCourierSegment] {
        return query.apply(store.list())
    }
}
