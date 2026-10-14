import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending courier windows by code.
    protocol PendingCourierWindowStore {
        func find(_ code: String) -> PendingCourierWindow?
        func save(_ item: PendingCourierWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCourierWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCourierWindowStore: PendingCourierWindowStore {
        var items: [String: PendingCourierWindow]
        var order: [String]

        init(items: [String: PendingCourierWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCourierWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCourierWindow) {
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

        func list() -> [PendingCourierWindow] {
            var out: [PendingCourierWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCourierWindowStore() -> any PendingCourierWindowStore {
        return MemoryPendingCourierWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCourierWindowStore: PendingCourierWindowStore {
        var inner: MemoryPendingCourierWindowStore
        var cache: TTLCache<PendingCourierWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCourierWindowStore, cache: TTLCache<PendingCourierWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCourierWindow? {
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

        func save(_ item: PendingCourierWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCourierWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingCourierWindowStore(_ inner: MemoryPendingCourierWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCourierWindowStore {
        return CachedPendingCourierWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending courier windows. Empty fields match all.
    final class PendingCourierWindowQuery {
        var locale: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRetries: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCourierWindow) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingCourierWindow]) -> [PendingCourierWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCourierWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCourierWindows(_ store: any PendingCourierWindowStore, query: PendingCourierWindowQuery) -> [PendingCourierWindow] {
        return query.apply(store.list())
    }
}
