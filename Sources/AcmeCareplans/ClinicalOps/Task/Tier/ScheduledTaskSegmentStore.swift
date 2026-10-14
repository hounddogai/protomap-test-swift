import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled task segments by code.
    protocol ScheduledTaskSegmentStore {
        func find(_ code: String) -> ScheduledTaskSegment?
        func save(_ item: ScheduledTaskSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledTaskSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledTaskSegmentStore: ScheduledTaskSegmentStore {
        var items: [String: ScheduledTaskSegment]
        var order: [String]

        init(items: [String: ScheduledTaskSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledTaskSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledTaskSegment) {
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

        func list() -> [ScheduledTaskSegment] {
            var out: [ScheduledTaskSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledTaskSegmentStore() -> any ScheduledTaskSegmentStore {
        return MemoryScheduledTaskSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledTaskSegmentStore: ScheduledTaskSegmentStore {
        var inner: MemoryScheduledTaskSegmentStore
        var cache: TTLCache<ScheduledTaskSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledTaskSegmentStore, cache: TTLCache<ScheduledTaskSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledTaskSegment? {
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

        func save(_ item: ScheduledTaskSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledTaskSegment] {
            return inner.list()
        }
    }

    static func newCachedScheduledTaskSegmentStore(_ inner: MemoryScheduledTaskSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledTaskSegmentStore {
        return CachedScheduledTaskSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled task segments. Empty fields match all.
    final class ScheduledTaskSegmentQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledTaskSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledTaskSegment]) -> [ScheduledTaskSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledTaskSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledTaskSegments(_ store: any ScheduledTaskSegmentStore, query: ScheduledTaskSegmentQuery) -> [ScheduledTaskSegment] {
        return query.apply(store.list())
    }
}
