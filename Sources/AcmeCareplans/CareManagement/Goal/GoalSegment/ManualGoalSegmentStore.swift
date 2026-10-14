import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual goal segments by code.
    protocol ManualGoalSegmentStore {
        func find(_ code: String) -> ManualGoalSegment?
        func save(_ item: ManualGoalSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ManualGoalSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualGoalSegmentStore: ManualGoalSegmentStore {
        var items: [String: ManualGoalSegment]
        var order: [String]

        init(items: [String: ManualGoalSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualGoalSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualGoalSegment) {
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

        func list() -> [ManualGoalSegment] {
            var out: [ManualGoalSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualGoalSegmentStore() -> any ManualGoalSegmentStore {
        return MemoryManualGoalSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualGoalSegmentStore: ManualGoalSegmentStore {
        var inner: MemoryManualGoalSegmentStore
        var cache: TTLCache<ManualGoalSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualGoalSegmentStore, cache: TTLCache<ManualGoalSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualGoalSegment? {
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

        func save(_ item: ManualGoalSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualGoalSegment] {
            return inner.list()
        }
    }

    static func newCachedManualGoalSegmentStore(_ inner: MemoryManualGoalSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualGoalSegmentStore {
        return CachedManualGoalSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual goal segments. Empty fields match all.
    final class ManualGoalSegmentQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualGoalSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualGoalSegment]) -> [ManualGoalSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualGoalSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualGoalSegments(_ store: any ManualGoalSegmentStore, query: ManualGoalSegmentQuery) -> [ManualGoalSegment] {
        return query.apply(store.list())
    }
}
