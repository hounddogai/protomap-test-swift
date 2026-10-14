import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient substitution claims by code.
    protocol LenientSubstitutionClaimStore {
        func find(_ code: String) -> LenientSubstitutionClaim?
        func save(_ item: LenientSubstitutionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSubstitutionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSubstitutionClaimStore: LenientSubstitutionClaimStore {
        var items: [String: LenientSubstitutionClaim]
        var order: [String]

        init(items: [String: LenientSubstitutionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSubstitutionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSubstitutionClaim) {
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

        func list() -> [LenientSubstitutionClaim] {
            var out: [LenientSubstitutionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSubstitutionClaimStore() -> any LenientSubstitutionClaimStore {
        return MemoryLenientSubstitutionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSubstitutionClaimStore: LenientSubstitutionClaimStore {
        var inner: MemoryLenientSubstitutionClaimStore
        var cache: TTLCache<LenientSubstitutionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSubstitutionClaimStore, cache: TTLCache<LenientSubstitutionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSubstitutionClaim? {
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

        func save(_ item: LenientSubstitutionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSubstitutionClaim] {
            return inner.list()
        }
    }

    static func newCachedLenientSubstitutionClaimStore(_ inner: MemoryLenientSubstitutionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSubstitutionClaimStore {
        return CachedLenientSubstitutionClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient substitution claims. Empty fields match all.
    final class LenientSubstitutionClaimQuery {
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

        func matches(_ item: LenientSubstitutionClaim) -> Bool {
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

        func apply(_ items: [LenientSubstitutionClaim]) -> [LenientSubstitutionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSubstitutionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSubstitutionClaims(_ store: any LenientSubstitutionClaimStore, query: LenientSubstitutionClaimQuery) -> [LenientSubstitutionClaim] {
        return query.apply(store.list())
    }
}
