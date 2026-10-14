import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled isolation segments by code.
    protocol ScheduledIsolationSegmentStore {
        func find(_ code: String) -> ScheduledIsolationSegment?
        func save(_ item: ScheduledIsolationSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledIsolationSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledIsolationSegmentStore: ScheduledIsolationSegmentStore {
        var items: [String: ScheduledIsolationSegment]
        var order: [String]

        init(items: [String: ScheduledIsolationSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledIsolationSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledIsolationSegment) {
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

        func list() -> [ScheduledIsolationSegment] {
            var out: [ScheduledIsolationSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledIsolationSegmentStore() -> any ScheduledIsolationSegmentStore {
        return MemoryScheduledIsolationSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledIsolationSegmentStore: ScheduledIsolationSegmentStore {
        var inner: MemoryScheduledIsolationSegmentStore
        var cache: TTLCache<ScheduledIsolationSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledIsolationSegmentStore, cache: TTLCache<ScheduledIsolationSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledIsolationSegment? {
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

        func save(_ item: ScheduledIsolationSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledIsolationSegment] {
            return inner.list()
        }
    }

    static func newCachedScheduledIsolationSegmentStore(_ inner: MemoryScheduledIsolationSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledIsolationSegmentStore {
        return CachedScheduledIsolationSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled isolation segments. Empty fields match all.
    final class ScheduledIsolationSegmentQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledIsolationSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledIsolationSegment]) -> [ScheduledIsolationSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledIsolationSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledIsolationSegments(_ store: any ScheduledIsolationSegmentStore, query: ScheduledIsolationSegmentQuery) -> [ScheduledIsolationSegment] {
        return query.apply(store.list())
    }
}
