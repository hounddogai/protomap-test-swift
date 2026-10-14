import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional acuity plan claims by code.
    protocol RegionalAcuityPlanClaimStore {
        func find(_ code: String) -> RegionalAcuityPlanClaim?
        func save(_ item: RegionalAcuityPlanClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAcuityPlanClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAcuityPlanClaimStore: RegionalAcuityPlanClaimStore {
        var items: [String: RegionalAcuityPlanClaim]
        var order: [String]

        init(items: [String: RegionalAcuityPlanClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAcuityPlanClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAcuityPlanClaim) {
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

        func list() -> [RegionalAcuityPlanClaim] {
            var out: [RegionalAcuityPlanClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAcuityPlanClaimStore() -> any RegionalAcuityPlanClaimStore {
        return MemoryRegionalAcuityPlanClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAcuityPlanClaimStore: RegionalAcuityPlanClaimStore {
        var inner: MemoryRegionalAcuityPlanClaimStore
        var cache: TTLCache<RegionalAcuityPlanClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAcuityPlanClaimStore, cache: TTLCache<RegionalAcuityPlanClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAcuityPlanClaim? {
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

        func save(_ item: RegionalAcuityPlanClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAcuityPlanClaim] {
            return inner.list()
        }
    }

    static func newCachedRegionalAcuityPlanClaimStore(_ inner: MemoryRegionalAcuityPlanClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAcuityPlanClaimStore {
        return CachedRegionalAcuityPlanClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional acuity plan claims. Empty fields match all.
    final class RegionalAcuityPlanClaimQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAcuityPlanClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAcuityPlanClaim]) -> [RegionalAcuityPlanClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAcuityPlanClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAcuityPlanClaims(_ store: any RegionalAcuityPlanClaimStore, query: RegionalAcuityPlanClaimQuery) -> [RegionalAcuityPlanClaim] {
        return query.apply(store.list())
    }
}
