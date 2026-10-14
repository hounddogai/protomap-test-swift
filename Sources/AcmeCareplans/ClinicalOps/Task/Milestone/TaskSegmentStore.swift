import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task segments by code.
    protocol TaskSegmentStore {
        func find(_ code: String) -> TaskSegment?
        func save(_ item: TaskSegment)
        func remove(_ code: String) -> Bool
        func list() -> [TaskSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskSegmentStore: TaskSegmentStore {
        var items: [String: TaskSegment]
        var order: [String]

        init(items: [String: TaskSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskSegment) {
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

        func list() -> [TaskSegment] {
            var out: [TaskSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskSegmentStore() -> any TaskSegmentStore {
        return MemoryTaskSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskSegmentStore: TaskSegmentStore {
        var inner: MemoryTaskSegmentStore
        var cache: TTLCache<TaskSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskSegmentStore, cache: TTLCache<TaskSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskSegment? {
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

        func save(_ item: TaskSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskSegment] {
            return inner.list()
        }
    }

    static func newCachedTaskSegmentStore(_ inner: MemoryTaskSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskSegmentStore {
        return CachedTaskSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task segments. Empty fields match all.
    final class TaskSegmentQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskSegment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskSegment]) -> [TaskSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskSegments(_ store: any TaskSegmentStore, query: TaskSegmentQuery) -> [TaskSegment] {
        return query.apply(store.list())
    }
}
