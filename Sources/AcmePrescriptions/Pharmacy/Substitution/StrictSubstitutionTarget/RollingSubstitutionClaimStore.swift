import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling substitution claims by code.
    protocol RollingSubstitutionClaimStore {
        func find(_ code: String) -> RollingSubstitutionClaim?
        func save(_ item: RollingSubstitutionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RollingSubstitutionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingSubstitutionClaimStore: RollingSubstitutionClaimStore {
        var items: [String: RollingSubstitutionClaim]
        var order: [String]

        init(items: [String: RollingSubstitutionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingSubstitutionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingSubstitutionClaim) {
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

        func list() -> [RollingSubstitutionClaim] {
            var out: [RollingSubstitutionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingSubstitutionClaimStore() -> any RollingSubstitutionClaimStore {
        return MemoryRollingSubstitutionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingSubstitutionClaimStore: RollingSubstitutionClaimStore {
        var inner: MemoryRollingSubstitutionClaimStore
        var cache: TTLCache<RollingSubstitutionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingSubstitutionClaimStore, cache: TTLCache<RollingSubstitutionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingSubstitutionClaim? {
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

        func save(_ item: RollingSubstitutionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingSubstitutionClaim] {
            return inner.list()
        }
    }

    static func newCachedRollingSubstitutionClaimStore(_ inner: MemoryRollingSubstitutionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingSubstitutionClaimStore {
        return CachedRollingSubstitutionClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling substitution claims. Empty fields match all.
    final class RollingSubstitutionClaimQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingSubstitutionClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingSubstitutionClaim]) -> [RollingSubstitutionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingSubstitutionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingSubstitutionClaims(_ store: any RollingSubstitutionClaimStore, query: RollingSubstitutionClaimQuery) -> [RollingSubstitutionClaim] {
        return query.apply(store.list())
    }
}
