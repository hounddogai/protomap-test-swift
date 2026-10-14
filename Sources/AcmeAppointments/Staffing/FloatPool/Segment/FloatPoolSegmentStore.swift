import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool segments by code.
    protocol FloatPoolSegmentStore {
        func find(_ code: String) -> FloatPoolSegment?
        func save(_ item: FloatPoolSegment)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolSegmentStore: FloatPoolSegmentStore {
        var items: [String: FloatPoolSegment]
        var order: [String]

        init(items: [String: FloatPoolSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolSegment) {
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

        func list() -> [FloatPoolSegment] {
            var out: [FloatPoolSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolSegmentStore() -> any FloatPoolSegmentStore {
        return MemoryFloatPoolSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolSegmentStore: FloatPoolSegmentStore {
        var inner: MemoryFloatPoolSegmentStore
        var cache: TTLCache<FloatPoolSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolSegmentStore, cache: TTLCache<FloatPoolSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolSegment? {
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

        func save(_ item: FloatPoolSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolSegment] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolSegmentStore(_ inner: MemoryFloatPoolSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolSegmentStore {
        return CachedFloatPoolSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool segments. Empty fields match all.
    final class FloatPoolSegmentQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolSegment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolSegment]) -> [FloatPoolSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolSegments(_ store: any FloatPoolSegmentStore, query: FloatPoolSegmentQuery) -> [FloatPoolSegment] {
        return query.apply(store.list())
    }
}
