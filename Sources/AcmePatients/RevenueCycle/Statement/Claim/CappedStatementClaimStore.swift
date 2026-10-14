import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped statement claims by code.
    protocol CappedStatementClaimStore {
        func find(_ code: String) -> CappedStatementClaim?
        func save(_ item: CappedStatementClaim)
        func remove(_ code: String) -> Bool
        func list() -> [CappedStatementClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedStatementClaimStore: CappedStatementClaimStore {
        var items: [String: CappedStatementClaim]
        var order: [String]

        init(items: [String: CappedStatementClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedStatementClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedStatementClaim) {
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

        func list() -> [CappedStatementClaim] {
            var out: [CappedStatementClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedStatementClaimStore() -> any CappedStatementClaimStore {
        return MemoryCappedStatementClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedStatementClaimStore: CappedStatementClaimStore {
        var inner: MemoryCappedStatementClaimStore
        var cache: TTLCache<CappedStatementClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedStatementClaimStore, cache: TTLCache<CappedStatementClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedStatementClaim? {
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

        func save(_ item: CappedStatementClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedStatementClaim] {
            return inner.list()
        }
    }

    static func newCachedCappedStatementClaimStore(_ inner: MemoryCappedStatementClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedStatementClaimStore {
        return CachedCappedStatementClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped statement claims. Empty fields match all.
    final class CappedStatementClaimQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedStatementClaim) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedStatementClaim]) -> [CappedStatementClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedStatementClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedStatementClaims(_ store: any CappedStatementClaimStore, query: CappedStatementClaimQuery) -> [CappedStatementClaim] {
        return query.apply(store.list())
    }
}
