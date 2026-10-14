import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled language cycles by code.
    protocol ScheduledLanguageCycleStore {
        func find(_ code: String) -> ScheduledLanguageCycle?
        func save(_ item: ScheduledLanguageCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledLanguageCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledLanguageCycleStore: ScheduledLanguageCycleStore {
        var items: [String: ScheduledLanguageCycle]
        var order: [String]

        init(items: [String: ScheduledLanguageCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledLanguageCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledLanguageCycle) {
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

        func list() -> [ScheduledLanguageCycle] {
            var out: [ScheduledLanguageCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledLanguageCycleStore() -> any ScheduledLanguageCycleStore {
        return MemoryScheduledLanguageCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledLanguageCycleStore: ScheduledLanguageCycleStore {
        var inner: MemoryScheduledLanguageCycleStore
        var cache: TTLCache<ScheduledLanguageCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledLanguageCycleStore, cache: TTLCache<ScheduledLanguageCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledLanguageCycle? {
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

        func save(_ item: ScheduledLanguageCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledLanguageCycle] {
            return inner.list()
        }
    }

    static func newCachedScheduledLanguageCycleStore(_ inner: MemoryScheduledLanguageCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledLanguageCycleStore {
        return CachedScheduledLanguageCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled language cycles. Empty fields match all.
    final class ScheduledLanguageCycleQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledLanguageCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledLanguageCycle]) -> [ScheduledLanguageCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledLanguageCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledLanguageCycles(_ store: any ScheduledLanguageCycleStore, query: ScheduledLanguageCycleQuery) -> [ScheduledLanguageCycle] {
        return query.apply(store.list())
    }
}
