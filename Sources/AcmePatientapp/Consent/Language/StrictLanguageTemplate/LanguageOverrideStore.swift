import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language overrides by code.
    protocol LanguageOverrideStore {
        func find(_ code: String) -> LanguageOverride?
        func save(_ item: LanguageOverride)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageOverrideStore: LanguageOverrideStore {
        var items: [String: LanguageOverride]
        var order: [String]

        init(items: [String: LanguageOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageOverride) {
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

        func list() -> [LanguageOverride] {
            var out: [LanguageOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageOverrideStore() -> any LanguageOverrideStore {
        return MemoryLanguageOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageOverrideStore: LanguageOverrideStore {
        var inner: MemoryLanguageOverrideStore
        var cache: TTLCache<LanguageOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageOverrideStore, cache: TTLCache<LanguageOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageOverride? {
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

        func save(_ item: LanguageOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageOverride] {
            return inner.list()
        }
    }

    static func newCachedLanguageOverrideStore(_ inner: MemoryLanguageOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageOverrideStore {
        return CachedLanguageOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language overrides. Empty fields match all.
    final class LanguageOverrideQuery {
        var unit: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [LanguageOverride]) -> [LanguageOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageOverrides(_ store: any LanguageOverrideStore, query: LanguageOverrideQuery) -> [LanguageOverride] {
        return query.apply(store.list())
    }
}
