import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal records by code.
    protocol GoalRecordStore {
        func find(_ code: String) -> GoalRecord?
        func save(_ item: GoalRecord)
        func remove(_ code: String) -> Bool
        func list() -> [GoalRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalRecordStore: GoalRecordStore {
        var items: [String: GoalRecord]
        var order: [String]

        init(items: [String: GoalRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalRecord) {
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

        func list() -> [GoalRecord] {
            var out: [GoalRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalRecordStore() -> any GoalRecordStore {
        return MemoryGoalRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalRecordStore: GoalRecordStore {
        var inner: MemoryGoalRecordStore
        var cache: TTLCache<GoalRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalRecordStore, cache: TTLCache<GoalRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalRecord? {
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

        func save(_ item: GoalRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalRecord] {
            return inner.list()
        }
    }

    static func newCachedGoalRecordStore(_ inner: MemoryGoalRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalRecordStore {
        return CachedGoalRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal records. Empty fields match all.
    final class GoalRecordQuery {
        var segment: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalRecord) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [GoalRecord]) -> [GoalRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalRecords(_ store: any GoalRecordStore, query: GoalRecordQuery) -> [GoalRecord] {
        return query.apply(store.list())
    }
}
