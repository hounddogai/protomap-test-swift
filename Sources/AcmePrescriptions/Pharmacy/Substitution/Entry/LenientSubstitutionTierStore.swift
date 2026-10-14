import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient substitution tiers by code.
    protocol LenientSubstitutionTierStore {
        func find(_ code: String) -> LenientSubstitutionTier?
        func save(_ item: LenientSubstitutionTier)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSubstitutionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSubstitutionTierStore: LenientSubstitutionTierStore {
        var items: [String: LenientSubstitutionTier]
        var order: [String]

        init(items: [String: LenientSubstitutionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSubstitutionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSubstitutionTier) {
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

        func list() -> [LenientSubstitutionTier] {
            var out: [LenientSubstitutionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSubstitutionTierStore() -> any LenientSubstitutionTierStore {
        return MemoryLenientSubstitutionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSubstitutionTierStore: LenientSubstitutionTierStore {
        var inner: MemoryLenientSubstitutionTierStore
        var cache: TTLCache<LenientSubstitutionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSubstitutionTierStore, cache: TTLCache<LenientSubstitutionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSubstitutionTier? {
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

        func save(_ item: LenientSubstitutionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSubstitutionTier] {
            return inner.list()
        }
    }

    static func newCachedLenientSubstitutionTierStore(_ inner: MemoryLenientSubstitutionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSubstitutionTierStore {
        return CachedLenientSubstitutionTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient substitution tiers. Empty fields match all.
    final class LenientSubstitutionTierQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSubstitutionTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSubstitutionTier]) -> [LenientSubstitutionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSubstitutionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSubstitutionTiers(_ store: any LenientSubstitutionTierStore, query: LenientSubstitutionTierQuery) -> [LenientSubstitutionTier] {
        return query.apply(store.list())
    }
}
