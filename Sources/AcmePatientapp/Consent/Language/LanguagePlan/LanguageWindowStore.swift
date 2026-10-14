import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language windows by code.
    protocol LanguageWindowStore {
        func find(_ code: String) -> LanguageWindow?
        func save(_ item: LanguageWindow)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageWindowStore: LanguageWindowStore {
        var items: [String: LanguageWindow]
        var order: [String]

        init(items: [String: LanguageWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageWindow) {
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

        func list() -> [LanguageWindow] {
            var out: [LanguageWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageWindowStore() -> any LanguageWindowStore {
        return MemoryLanguageWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageWindowStore: LanguageWindowStore {
        var inner: MemoryLanguageWindowStore
        var cache: TTLCache<LanguageWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageWindowStore, cache: TTLCache<LanguageWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageWindow? {
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

        func save(_ item: LanguageWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageWindow] {
            return inner.list()
        }
    }

    static func newCachedLanguageWindowStore(_ inner: MemoryLanguageWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageWindowStore {
        return CachedLanguageWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language windows. Empty fields match all.
    final class LanguageWindowQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageWindow]) -> [LanguageWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageWindows(_ store: any LanguageWindowStore, query: LanguageWindowQuery) -> [LanguageWindow] {
        return query.apply(store.list())
    }
}
