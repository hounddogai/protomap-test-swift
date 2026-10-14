import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending proxy schedules by code.
    protocol PendingProxyScheduleStore {
        func find(_ code: String) -> PendingProxySchedule?
        func save(_ item: PendingProxySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [PendingProxySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingProxyScheduleStore: PendingProxyScheduleStore {
        var items: [String: PendingProxySchedule]
        var order: [String]

        init(items: [String: PendingProxySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingProxySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingProxySchedule) {
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

        func list() -> [PendingProxySchedule] {
            var out: [PendingProxySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingProxyScheduleStore() -> any PendingProxyScheduleStore {
        return MemoryPendingProxyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingProxyScheduleStore: PendingProxyScheduleStore {
        var inner: MemoryPendingProxyScheduleStore
        var cache: TTLCache<PendingProxySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingProxyScheduleStore, cache: TTLCache<PendingProxySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingProxySchedule? {
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

        func save(_ item: PendingProxySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingProxySchedule] {
            return inner.list()
        }
    }

    static func newCachedPendingProxyScheduleStore(_ inner: MemoryPendingProxyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingProxyScheduleStore {
        return CachedPendingProxyScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending proxy schedules. Empty fields match all.
    final class PendingProxyScheduleQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingProxySchedule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingProxySchedule]) -> [PendingProxySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingProxySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingProxySchedules(_ store: any PendingProxyScheduleStore, query: PendingProxyScheduleQuery) -> [PendingProxySchedule] {
        return query.apply(store.list())
    }
}
