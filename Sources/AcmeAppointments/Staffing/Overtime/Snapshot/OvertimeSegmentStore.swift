import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime segments by code.
    protocol OvertimeSegmentStore {
        func find(_ code: String) -> OvertimeSegment?
        func save(_ item: OvertimeSegment)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeSegmentStore: OvertimeSegmentStore {
        var items: [String: OvertimeSegment]
        var order: [String]

        init(items: [String: OvertimeSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeSegment) {
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

        func list() -> [OvertimeSegment] {
            var out: [OvertimeSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeSegmentStore() -> any OvertimeSegmentStore {
        return MemoryOvertimeSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeSegmentStore: OvertimeSegmentStore {
        var inner: MemoryOvertimeSegmentStore
        var cache: TTLCache<OvertimeSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeSegmentStore, cache: TTLCache<OvertimeSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeSegment? {
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

        func save(_ item: OvertimeSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeSegment] {
            return inner.list()
        }
    }

    static func newCachedOvertimeSegmentStore(_ inner: MemoryOvertimeSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeSegmentStore {
        return CachedOvertimeSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime segments. Empty fields match all.
    final class OvertimeSegmentQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeSegment]) -> [OvertimeSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeSegments(_ store: any OvertimeSegmentStore, query: OvertimeSegmentQuery) -> [OvertimeSegment] {
        return query.apply(store.list())
    }
}
