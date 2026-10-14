import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network schedules by code.
    protocol NetworkScheduleStore {
        func find(_ code: String) -> NetworkSchedule?
        func save(_ item: NetworkSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkScheduleStore: NetworkScheduleStore {
        var items: [String: NetworkSchedule]
        var order: [String]

        init(items: [String: NetworkSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkSchedule) {
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

        func list() -> [NetworkSchedule] {
            var out: [NetworkSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkScheduleStore() -> any NetworkScheduleStore {
        return MemoryNetworkScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkScheduleStore: NetworkScheduleStore {
        var inner: MemoryNetworkScheduleStore
        var cache: TTLCache<NetworkSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkScheduleStore, cache: TTLCache<NetworkSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkSchedule? {
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

        func save(_ item: NetworkSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkSchedule] {
            return inner.list()
        }
    }

    static func newCachedNetworkScheduleStore(_ inner: MemoryNetworkScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkScheduleStore {
        return CachedNetworkScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network schedules. Empty fields match all.
    final class NetworkScheduleQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [NetworkSchedule]) -> [NetworkSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkSchedules(_ store: any NetworkScheduleStore, query: NetworkScheduleQuery) -> [NetworkSchedule] {
        return query.apply(store.list())
    }
}
