import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language cycles by code.
    protocol LanguageCycleStore {
        func find(_ code: String) -> LanguageCycle?
        func save(_ item: LanguageCycle)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageCycleStore: LanguageCycleStore {
        var items: [String: LanguageCycle]
        var order: [String]

        init(items: [String: LanguageCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageCycle) {
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

        func list() -> [LanguageCycle] {
            var out: [LanguageCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageCycleStore() -> any LanguageCycleStore {
        return MemoryLanguageCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageCycleStore: LanguageCycleStore {
        var inner: MemoryLanguageCycleStore
        var cache: TTLCache<LanguageCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageCycleStore, cache: TTLCache<LanguageCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageCycle? {
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

        func save(_ item: LanguageCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageCycle] {
            return inner.list()
        }
    }

    static func newCachedLanguageCycleStore(_ inner: MemoryLanguageCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageCycleStore {
        return CachedLanguageCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language cycles. Empty fields match all.
    final class LanguageCycleQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageCycle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LanguageCycle]) -> [LanguageCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageCycles(_ store: any LanguageCycleStore, query: LanguageCycleQuery) -> [LanguageCycle] {
        return query.apply(store.list())
    }
}
