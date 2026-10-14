import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual proxy schedules by code.
    protocol ManualProxyScheduleStore {
        func find(_ code: String) -> ManualProxySchedule?
        func save(_ item: ManualProxySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ManualProxySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualProxyScheduleStore: ManualProxyScheduleStore {
        var items: [String: ManualProxySchedule]
        var order: [String]

        init(items: [String: ManualProxySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualProxySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualProxySchedule) {
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

        func list() -> [ManualProxySchedule] {
            var out: [ManualProxySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualProxyScheduleStore() -> any ManualProxyScheduleStore {
        return MemoryManualProxyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualProxyScheduleStore: ManualProxyScheduleStore {
        var inner: MemoryManualProxyScheduleStore
        var cache: TTLCache<ManualProxySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualProxyScheduleStore, cache: TTLCache<ManualProxySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualProxySchedule? {
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

        func save(_ item: ManualProxySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualProxySchedule] {
            return inner.list()
        }
    }

    static func newCachedManualProxyScheduleStore(_ inner: MemoryManualProxyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualProxyScheduleStore {
        return CachedManualProxyScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual proxy schedules. Empty fields match all.
    final class ManualProxyScheduleQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualProxySchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualProxySchedule]) -> [ManualProxySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualProxySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualProxySchedules(_ store: any ManualProxyScheduleStore, query: ManualProxyScheduleQuery) -> [ManualProxySchedule] {
        return query.apply(store.list())
    }
}
