import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global closure claims by code.
    protocol GlobalClosureClaimStore {
        func find(_ code: String) -> GlobalClosureClaim?
        func save(_ item: GlobalClosureClaim)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalClosureClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalClosureClaimStore: GlobalClosureClaimStore {
        var items: [String: GlobalClosureClaim]
        var order: [String]

        init(items: [String: GlobalClosureClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalClosureClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalClosureClaim) {
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

        func list() -> [GlobalClosureClaim] {
            var out: [GlobalClosureClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalClosureClaimStore() -> any GlobalClosureClaimStore {
        return MemoryGlobalClosureClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalClosureClaimStore: GlobalClosureClaimStore {
        var inner: MemoryGlobalClosureClaimStore
        var cache: TTLCache<GlobalClosureClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalClosureClaimStore, cache: TTLCache<GlobalClosureClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalClosureClaim? {
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

        func save(_ item: GlobalClosureClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalClosureClaim] {
            return inner.list()
        }
    }

    static func newCachedGlobalClosureClaimStore(_ inner: MemoryGlobalClosureClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalClosureClaimStore {
        return CachedGlobalClosureClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global closure claims. Empty fields match all.
    final class GlobalClosureClaimQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalClosureClaim) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [GlobalClosureClaim]) -> [GlobalClosureClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalClosureClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalClosureClaims(_ store: any GlobalClosureClaimStore, query: GlobalClosureClaimQuery) -> [GlobalClosureClaim] {
        return query.apply(store.list())
    }
}
