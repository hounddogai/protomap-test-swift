import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution claims by code.
    protocol SubstitutionClaimStore {
        func find(_ code: String) -> SubstitutionClaim?
        func save(_ item: SubstitutionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionClaimStore: SubstitutionClaimStore {
        var items: [String: SubstitutionClaim]
        var order: [String]

        init(items: [String: SubstitutionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionClaim) {
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

        func list() -> [SubstitutionClaim] {
            var out: [SubstitutionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionClaimStore() -> any SubstitutionClaimStore {
        return MemorySubstitutionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionClaimStore: SubstitutionClaimStore {
        var inner: MemorySubstitutionClaimStore
        var cache: TTLCache<SubstitutionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionClaimStore, cache: TTLCache<SubstitutionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionClaim? {
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

        func save(_ item: SubstitutionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionClaim] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionClaimStore(_ inner: MemorySubstitutionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionClaimStore {
        return CachedSubstitutionClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution claims. Empty fields match all.
    final class SubstitutionClaimQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionClaim]) -> [SubstitutionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionClaims(_ store: any SubstitutionClaimStore, query: SubstitutionClaimQuery) -> [SubstitutionClaim] {
        return query.apply(store.list())
    }
}
