import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance schedules by code.
    protocol RemittanceScheduleStore {
        func find(_ code: String) -> RemittanceSchedule?
        func save(_ item: RemittanceSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceScheduleStore: RemittanceScheduleStore {
        var items: [String: RemittanceSchedule]
        var order: [String]

        init(items: [String: RemittanceSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceSchedule) {
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

        func list() -> [RemittanceSchedule] {
            var out: [RemittanceSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceScheduleStore() -> any RemittanceScheduleStore {
        return MemoryRemittanceScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceScheduleStore: RemittanceScheduleStore {
        var inner: MemoryRemittanceScheduleStore
        var cache: TTLCache<RemittanceSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceScheduleStore, cache: TTLCache<RemittanceSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceSchedule? {
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

        func save(_ item: RemittanceSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceSchedule] {
            return inner.list()
        }
    }

    static func newCachedRemittanceScheduleStore(_ inner: MemoryRemittanceScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceScheduleStore {
        return CachedRemittanceScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance schedules. Empty fields match all.
    final class RemittanceScheduleQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceSchedule]) -> [RemittanceSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceSchedules(_ store: any RemittanceScheduleStore, query: RemittanceScheduleQuery) -> [RemittanceSchedule] {
        return query.apply(store.list())
    }
}
