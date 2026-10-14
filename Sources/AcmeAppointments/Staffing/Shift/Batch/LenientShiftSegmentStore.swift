import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient shift segments by code.
    protocol LenientShiftSegmentStore {
        func find(_ code: String) -> LenientShiftSegment?
        func save(_ item: LenientShiftSegment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientShiftSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientShiftSegmentStore: LenientShiftSegmentStore {
        var items: [String: LenientShiftSegment]
        var order: [String]

        init(items: [String: LenientShiftSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientShiftSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientShiftSegment) {
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

        func list() -> [LenientShiftSegment] {
            var out: [LenientShiftSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientShiftSegmentStore() -> any LenientShiftSegmentStore {
        return MemoryLenientShiftSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientShiftSegmentStore: LenientShiftSegmentStore {
        var inner: MemoryLenientShiftSegmentStore
        var cache: TTLCache<LenientShiftSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientShiftSegmentStore, cache: TTLCache<LenientShiftSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientShiftSegment? {
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

        func save(_ item: LenientShiftSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientShiftSegment] {
            return inner.list()
        }
    }

    static func newCachedLenientShiftSegmentStore(_ inner: MemoryLenientShiftSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientShiftSegmentStore {
        return CachedLenientShiftSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient shift segments. Empty fields match all.
    final class LenientShiftSegmentQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientShiftSegment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientShiftSegment]) -> [LenientShiftSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientShiftSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientShiftSegments(_ store: any LenientShiftSegmentStore, query: LenientShiftSegmentQuery) -> [LenientShiftSegment] {
        return query.apply(store.list())
    }
}
