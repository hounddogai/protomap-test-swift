import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary acuity plan targets by code.
    protocol PrimaryAcuityPlanTargetStore {
        func find(_ code: String) -> PrimaryAcuityPlanTarget?
        func save(_ item: PrimaryAcuityPlanTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAcuityPlanTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAcuityPlanTargetStore: PrimaryAcuityPlanTargetStore {
        var items: [String: PrimaryAcuityPlanTarget]
        var order: [String]

        init(items: [String: PrimaryAcuityPlanTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAcuityPlanTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAcuityPlanTarget) {
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

        func list() -> [PrimaryAcuityPlanTarget] {
            var out: [PrimaryAcuityPlanTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAcuityPlanTargetStore() -> any PrimaryAcuityPlanTargetStore {
        return MemoryPrimaryAcuityPlanTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAcuityPlanTargetStore: PrimaryAcuityPlanTargetStore {
        var inner: MemoryPrimaryAcuityPlanTargetStore
        var cache: TTLCache<PrimaryAcuityPlanTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAcuityPlanTargetStore, cache: TTLCache<PrimaryAcuityPlanTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAcuityPlanTarget? {
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

        func save(_ item: PrimaryAcuityPlanTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAcuityPlanTarget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAcuityPlanTargetStore(_ inner: MemoryPrimaryAcuityPlanTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAcuityPlanTargetStore {
        return CachedPrimaryAcuityPlanTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary acuity plan targets. Empty fields match all.
    final class PrimaryAcuityPlanTargetQuery {
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

        func matches(_ item: PrimaryAcuityPlanTarget) -> Bool {
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

        func apply(_ items: [PrimaryAcuityPlanTarget]) -> [PrimaryAcuityPlanTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAcuityPlanTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAcuityPlanTargets(_ store: any PrimaryAcuityPlanTargetStore, query: PrimaryAcuityPlanTargetQuery) -> [PrimaryAcuityPlanTarget] {
        return query.apply(store.list())
    }
}
