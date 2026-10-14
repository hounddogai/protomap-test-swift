import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling study segments by code.
    protocol RollingStudySegmentStore {
        func find(_ code: String) -> RollingStudySegment?
        func save(_ item: RollingStudySegment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingStudySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingStudySegmentStore: RollingStudySegmentStore {
        var items: [String: RollingStudySegment]
        var order: [String]

        init(items: [String: RollingStudySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingStudySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingStudySegment) {
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

        func list() -> [RollingStudySegment] {
            var out: [RollingStudySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingStudySegmentStore() -> any RollingStudySegmentStore {
        return MemoryRollingStudySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingStudySegmentStore: RollingStudySegmentStore {
        var inner: MemoryRollingStudySegmentStore
        var cache: TTLCache<RollingStudySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingStudySegmentStore, cache: TTLCache<RollingStudySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingStudySegment? {
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

        func save(_ item: RollingStudySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingStudySegment] {
            return inner.list()
        }
    }

    static func newCachedRollingStudySegmentStore(_ inner: MemoryRollingStudySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingStudySegmentStore {
        return CachedRollingStudySegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling study segments. Empty fields match all.
    final class RollingStudySegmentQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingStudySegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingStudySegment]) -> [RollingStudySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingStudySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingStudySegments(_ store: any RollingStudySegmentStore, query: RollingStudySegmentQuery) -> [RollingStudySegment] {
        return query.apply(store.list())
    }
}
