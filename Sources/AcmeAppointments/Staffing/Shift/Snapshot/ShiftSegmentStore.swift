import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift segments by code.
    protocol ShiftSegmentStore {
        func find(_ code: String) -> ShiftSegment?
        func save(_ item: ShiftSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftSegmentStore: ShiftSegmentStore {
        var items: [String: ShiftSegment]
        var order: [String]

        init(items: [String: ShiftSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftSegment) {
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

        func list() -> [ShiftSegment] {
            var out: [ShiftSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftSegmentStore() -> any ShiftSegmentStore {
        return MemoryShiftSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftSegmentStore: ShiftSegmentStore {
        var inner: MemoryShiftSegmentStore
        var cache: TTLCache<ShiftSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftSegmentStore, cache: TTLCache<ShiftSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftSegment? {
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

        func save(_ item: ShiftSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftSegment] {
            return inner.list()
        }
    }

    static func newCachedShiftSegmentStore(_ inner: MemoryShiftSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftSegmentStore {
        return CachedShiftSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift segments. Empty fields match all.
    final class ShiftSegmentQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftSegment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftSegment]) -> [ShiftSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftSegments(_ store: any ShiftSegmentStore, query: ShiftSegmentQuery) -> [ShiftSegment] {
        return query.apply(store.list())
    }
}
