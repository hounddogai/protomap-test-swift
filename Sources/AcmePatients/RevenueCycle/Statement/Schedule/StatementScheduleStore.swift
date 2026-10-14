import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement schedules by code.
    protocol StatementScheduleStore {
        func find(_ code: String) -> StatementSchedule?
        func save(_ item: StatementSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [StatementSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementScheduleStore: StatementScheduleStore {
        var items: [String: StatementSchedule]
        var order: [String]

        init(items: [String: StatementSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementSchedule) {
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

        func list() -> [StatementSchedule] {
            var out: [StatementSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementScheduleStore() -> any StatementScheduleStore {
        return MemoryStatementScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementScheduleStore: StatementScheduleStore {
        var inner: MemoryStatementScheduleStore
        var cache: TTLCache<StatementSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementScheduleStore, cache: TTLCache<StatementSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementSchedule? {
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

        func save(_ item: StatementSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementSchedule] {
            return inner.list()
        }
    }

    static func newCachedStatementScheduleStore(_ inner: MemoryStatementScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementScheduleStore {
        return CachedStatementScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement schedules. Empty fields match all.
    final class StatementScheduleQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementSchedule]) -> [StatementSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementSchedules(_ store: any StatementScheduleStore, query: StatementScheduleQuery) -> [StatementSchedule] {
        return query.apply(store.list())
    }
}
