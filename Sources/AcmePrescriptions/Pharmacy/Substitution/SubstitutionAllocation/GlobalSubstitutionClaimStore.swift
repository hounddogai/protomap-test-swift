import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global substitution claims by code.
    protocol GlobalSubstitutionClaimStore {
        func find(_ code: String) -> GlobalSubstitutionClaim?
        func save(_ item: GlobalSubstitutionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSubstitutionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSubstitutionClaimStore: GlobalSubstitutionClaimStore {
        var items: [String: GlobalSubstitutionClaim]
        var order: [String]

        init(items: [String: GlobalSubstitutionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSubstitutionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSubstitutionClaim) {
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

        func list() -> [GlobalSubstitutionClaim] {
            var out: [GlobalSubstitutionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSubstitutionClaimStore() -> any GlobalSubstitutionClaimStore {
        return MemoryGlobalSubstitutionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSubstitutionClaimStore: GlobalSubstitutionClaimStore {
        var inner: MemoryGlobalSubstitutionClaimStore
        var cache: TTLCache<GlobalSubstitutionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSubstitutionClaimStore, cache: TTLCache<GlobalSubstitutionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSubstitutionClaim? {
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

        func save(_ item: GlobalSubstitutionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSubstitutionClaim] {
            return inner.list()
        }
    }

    static func newCachedGlobalSubstitutionClaimStore(_ inner: MemoryGlobalSubstitutionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSubstitutionClaimStore {
        return CachedGlobalSubstitutionClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global substitution claims. Empty fields match all.
    final class GlobalSubstitutionClaimQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSubstitutionClaim) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSubstitutionClaim]) -> [GlobalSubstitutionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSubstitutionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSubstitutionClaims(_ store: any GlobalSubstitutionClaimStore, query: GlobalSubstitutionClaimQuery) -> [GlobalSubstitutionClaim] {
        return query.apply(store.list())
    }
}
