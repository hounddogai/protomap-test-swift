import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language tiers by code.
    protocol LanguageTierStore {
        func find(_ code: String) -> LanguageTier?
        func save(_ item: LanguageTier)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageTierStore: LanguageTierStore {
        var items: [String: LanguageTier]
        var order: [String]

        init(items: [String: LanguageTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageTier) {
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

        func list() -> [LanguageTier] {
            var out: [LanguageTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageTierStore() -> any LanguageTierStore {
        return MemoryLanguageTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageTierStore: LanguageTierStore {
        var inner: MemoryLanguageTierStore
        var cache: TTLCache<LanguageTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageTierStore, cache: TTLCache<LanguageTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageTier? {
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

        func save(_ item: LanguageTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageTier] {
            return inner.list()
        }
    }

    static func newCachedLanguageTierStore(_ inner: MemoryLanguageTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageTierStore {
        return CachedLanguageTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language tiers. Empty fields match all.
    final class LanguageTierQuery {
        var channel: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageTier) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageTier]) -> [LanguageTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageTiers(_ store: any LanguageTierStore, query: LanguageTierQuery) -> [LanguageTier] {
        return query.apply(store.list())
    }
}
