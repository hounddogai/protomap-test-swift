import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global task schedules by code.
    protocol GlobalTaskScheduleStore {
        func find(_ code: String) -> GlobalTaskSchedule?
        func save(_ item: GlobalTaskSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalTaskSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalTaskScheduleStore: GlobalTaskScheduleStore {
        var items: [String: GlobalTaskSchedule]
        var order: [String]

        init(items: [String: GlobalTaskSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalTaskSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalTaskSchedule) {
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

        func list() -> [GlobalTaskSchedule] {
            var out: [GlobalTaskSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalTaskScheduleStore() -> any GlobalTaskScheduleStore {
        return MemoryGlobalTaskScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalTaskScheduleStore: GlobalTaskScheduleStore {
        var inner: MemoryGlobalTaskScheduleStore
        var cache: TTLCache<GlobalTaskSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalTaskScheduleStore, cache: TTLCache<GlobalTaskSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalTaskSchedule? {
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

        func save(_ item: GlobalTaskSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalTaskSchedule] {
            return inner.list()
        }
    }

    static func newCachedGlobalTaskScheduleStore(_ inner: MemoryGlobalTaskScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalTaskScheduleStore {
        return CachedGlobalTaskScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global task schedules. Empty fields match all.
    final class GlobalTaskScheduleQuery {
        var channel: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalTaskSchedule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [GlobalTaskSchedule]) -> [GlobalTaskSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalTaskSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalTaskSchedules(_ store: any GlobalTaskScheduleStore, query: GlobalTaskScheduleQuery) -> [GlobalTaskSchedule] {
        return query.apply(store.list())
    }
}
