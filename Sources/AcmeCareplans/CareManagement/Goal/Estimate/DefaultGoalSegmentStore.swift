import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default goal segments by code.
    protocol DefaultGoalSegmentStore {
        func find(_ code: String) -> DefaultGoalSegment?
        func save(_ item: DefaultGoalSegment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultGoalSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultGoalSegmentStore: DefaultGoalSegmentStore {
        var items: [String: DefaultGoalSegment]
        var order: [String]

        init(items: [String: DefaultGoalSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultGoalSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultGoalSegment) {
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

        func list() -> [DefaultGoalSegment] {
            var out: [DefaultGoalSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultGoalSegmentStore() -> any DefaultGoalSegmentStore {
        return MemoryDefaultGoalSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultGoalSegmentStore: DefaultGoalSegmentStore {
        var inner: MemoryDefaultGoalSegmentStore
        var cache: TTLCache<DefaultGoalSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultGoalSegmentStore, cache: TTLCache<DefaultGoalSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultGoalSegment? {
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

        func save(_ item: DefaultGoalSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultGoalSegment] {
            return inner.list()
        }
    }

    static func newCachedDefaultGoalSegmentStore(_ inner: MemoryDefaultGoalSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultGoalSegmentStore {
        return CachedDefaultGoalSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default goal segments. Empty fields match all.
    final class DefaultGoalSegmentQuery {
        var facility: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultGoalSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultGoalSegment]) -> [DefaultGoalSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultGoalSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultGoalSegments(_ store: any DefaultGoalSegmentStore, query: DefaultGoalSegmentQuery) -> [DefaultGoalSegment] {
        return query.apply(store.list())
    }
}
