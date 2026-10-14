import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure windows by code.
    protocol ClosureWindowStore {
        func find(_ code: String) -> ClosureWindow?
        func save(_ item: ClosureWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureWindowStore: ClosureWindowStore {
        var items: [String: ClosureWindow]
        var order: [String]

        init(items: [String: ClosureWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureWindow) {
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

        func list() -> [ClosureWindow] {
            var out: [ClosureWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureWindowStore() -> any ClosureWindowStore {
        return MemoryClosureWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureWindowStore: ClosureWindowStore {
        var inner: MemoryClosureWindowStore
        var cache: TTLCache<ClosureWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureWindowStore, cache: TTLCache<ClosureWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureWindow? {
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

        func save(_ item: ClosureWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureWindow] {
            return inner.list()
        }
    }

    static func newCachedClosureWindowStore(_ inner: MemoryClosureWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureWindowStore {
        return CachedClosureWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure windows. Empty fields match all.
    final class ClosureWindowQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureWindow) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [ClosureWindow]) -> [ClosureWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureWindows(_ store: any ClosureWindowStore, query: ClosureWindowQuery) -> [ClosureWindow] {
        return query.apply(store.list())
    }
}
