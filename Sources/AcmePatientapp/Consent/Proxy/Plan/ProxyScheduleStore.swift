import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy schedules by code.
    protocol ProxyScheduleStore {
        func find(_ code: String) -> ProxySchedule?
        func save(_ item: ProxySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ProxySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyScheduleStore: ProxyScheduleStore {
        var items: [String: ProxySchedule]
        var order: [String]

        init(items: [String: ProxySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxySchedule) {
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

        func list() -> [ProxySchedule] {
            var out: [ProxySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyScheduleStore() -> any ProxyScheduleStore {
        return MemoryProxyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyScheduleStore: ProxyScheduleStore {
        var inner: MemoryProxyScheduleStore
        var cache: TTLCache<ProxySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyScheduleStore, cache: TTLCache<ProxySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxySchedule? {
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

        func save(_ item: ProxySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxySchedule] {
            return inner.list()
        }
    }

    static func newCachedProxyScheduleStore(_ inner: MemoryProxyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyScheduleStore {
        return CachedProxyScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy schedules. Empty fields match all.
    final class ProxyScheduleQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxySchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ProxySchedule]) -> [ProxySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxySchedules(_ store: any ProxyScheduleStore, query: ProxyScheduleQuery) -> [ProxySchedule] {
        return query.apply(store.list())
    }
}
