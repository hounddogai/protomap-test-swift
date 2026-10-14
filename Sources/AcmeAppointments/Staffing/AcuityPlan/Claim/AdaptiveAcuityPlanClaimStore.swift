import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive acuity plan claims by code.
    protocol AdaptiveAcuityPlanClaimStore {
        func find(_ code: String) -> AdaptiveAcuityPlanClaim?
        func save(_ item: AdaptiveAcuityPlanClaim)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAcuityPlanClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAcuityPlanClaimStore: AdaptiveAcuityPlanClaimStore {
        var items: [String: AdaptiveAcuityPlanClaim]
        var order: [String]

        init(items: [String: AdaptiveAcuityPlanClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAcuityPlanClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAcuityPlanClaim) {
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

        func list() -> [AdaptiveAcuityPlanClaim] {
            var out: [AdaptiveAcuityPlanClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAcuityPlanClaimStore() -> any AdaptiveAcuityPlanClaimStore {
        return MemoryAdaptiveAcuityPlanClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAcuityPlanClaimStore: AdaptiveAcuityPlanClaimStore {
        var inner: MemoryAdaptiveAcuityPlanClaimStore
        var cache: TTLCache<AdaptiveAcuityPlanClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAcuityPlanClaimStore, cache: TTLCache<AdaptiveAcuityPlanClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAcuityPlanClaim? {
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

        func save(_ item: AdaptiveAcuityPlanClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAcuityPlanClaim] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAcuityPlanClaimStore(_ inner: MemoryAdaptiveAcuityPlanClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAcuityPlanClaimStore {
        return CachedAdaptiveAcuityPlanClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive acuity plan claims. Empty fields match all.
    final class AdaptiveAcuityPlanClaimQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAcuityPlanClaim) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveAcuityPlanClaim]) -> [AdaptiveAcuityPlanClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAcuityPlanClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAcuityPlanClaims(_ store: any AdaptiveAcuityPlanClaimStore, query: AdaptiveAcuityPlanClaimQuery) -> [AdaptiveAcuityPlanClaim] {
        return query.apply(store.list())
    }
}
