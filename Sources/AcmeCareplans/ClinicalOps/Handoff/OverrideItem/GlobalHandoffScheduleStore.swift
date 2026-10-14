import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global handoff schedules by code.
    protocol GlobalHandoffScheduleStore {
        func find(_ code: String) -> GlobalHandoffSchedule?
        func save(_ item: GlobalHandoffSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalHandoffSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalHandoffScheduleStore: GlobalHandoffScheduleStore {
        var items: [String: GlobalHandoffSchedule]
        var order: [String]

        init(items: [String: GlobalHandoffSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalHandoffSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalHandoffSchedule) {
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

        func list() -> [GlobalHandoffSchedule] {
            var out: [GlobalHandoffSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalHandoffScheduleStore() -> any GlobalHandoffScheduleStore {
        return MemoryGlobalHandoffScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalHandoffScheduleStore: GlobalHandoffScheduleStore {
        var inner: MemoryGlobalHandoffScheduleStore
        var cache: TTLCache<GlobalHandoffSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalHandoffScheduleStore, cache: TTLCache<GlobalHandoffSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalHandoffSchedule? {
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

        func save(_ item: GlobalHandoffSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalHandoffSchedule] {
            return inner.list()
        }
    }

    static func newCachedGlobalHandoffScheduleStore(_ inner: MemoryGlobalHandoffScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalHandoffScheduleStore {
        return CachedGlobalHandoffScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global handoff schedules. Empty fields match all.
    final class GlobalHandoffScheduleQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalHandoffSchedule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [GlobalHandoffSchedule]) -> [GlobalHandoffSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalHandoffSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalHandoffSchedules(_ store: any GlobalHandoffScheduleStore, query: GlobalHandoffScheduleQuery) -> [GlobalHandoffSchedule] {
        return query.apply(store.list())
    }
}
