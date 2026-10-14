import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default substitution tiers by code.
    protocol DefaultSubstitutionTierStore {
        func find(_ code: String) -> DefaultSubstitutionTier?
        func save(_ item: DefaultSubstitutionTier)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSubstitutionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSubstitutionTierStore: DefaultSubstitutionTierStore {
        var items: [String: DefaultSubstitutionTier]
        var order: [String]

        init(items: [String: DefaultSubstitutionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSubstitutionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSubstitutionTier) {
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

        func list() -> [DefaultSubstitutionTier] {
            var out: [DefaultSubstitutionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSubstitutionTierStore() -> any DefaultSubstitutionTierStore {
        return MemoryDefaultSubstitutionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSubstitutionTierStore: DefaultSubstitutionTierStore {
        var inner: MemoryDefaultSubstitutionTierStore
        var cache: TTLCache<DefaultSubstitutionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSubstitutionTierStore, cache: TTLCache<DefaultSubstitutionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSubstitutionTier? {
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

        func save(_ item: DefaultSubstitutionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSubstitutionTier] {
            return inner.list()
        }
    }

    static func newCachedDefaultSubstitutionTierStore(_ inner: MemoryDefaultSubstitutionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSubstitutionTierStore {
        return CachedDefaultSubstitutionTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default substitution tiers. Empty fields match all.
    final class DefaultSubstitutionTierQuery {
        var category: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRetries: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSubstitutionTier) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [DefaultSubstitutionTier]) -> [DefaultSubstitutionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSubstitutionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSubstitutionTiers(_ store: any DefaultSubstitutionTierStore, query: DefaultSubstitutionTierQuery) -> [DefaultSubstitutionTier] {
        return query.apply(store.list())
    }
}
