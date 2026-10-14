import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted acuity plan proposals by code.
    protocol WeightedAcuityPlanProposalStore {
        func find(_ code: String) -> WeightedAcuityPlanProposal?
        func save(_ item: WeightedAcuityPlanProposal)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAcuityPlanProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAcuityPlanProposalStore: WeightedAcuityPlanProposalStore {
        var items: [String: WeightedAcuityPlanProposal]
        var order: [String]

        init(items: [String: WeightedAcuityPlanProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAcuityPlanProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAcuityPlanProposal) {
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

        func list() -> [WeightedAcuityPlanProposal] {
            var out: [WeightedAcuityPlanProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAcuityPlanProposalStore() -> any WeightedAcuityPlanProposalStore {
        return MemoryWeightedAcuityPlanProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAcuityPlanProposalStore: WeightedAcuityPlanProposalStore {
        var inner: MemoryWeightedAcuityPlanProposalStore
        var cache: TTLCache<WeightedAcuityPlanProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAcuityPlanProposalStore, cache: TTLCache<WeightedAcuityPlanProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAcuityPlanProposal? {
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

        func save(_ item: WeightedAcuityPlanProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAcuityPlanProposal] {
            return inner.list()
        }
    }

    static func newCachedWeightedAcuityPlanProposalStore(_ inner: MemoryWeightedAcuityPlanProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAcuityPlanProposalStore {
        return CachedWeightedAcuityPlanProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted acuity plan proposals. Empty fields match all.
    final class WeightedAcuityPlanProposalQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAcuityPlanProposal) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedAcuityPlanProposal]) -> [WeightedAcuityPlanProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAcuityPlanProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAcuityPlanProposals(_ store: any WeightedAcuityPlanProposalStore, query: WeightedAcuityPlanProposalQuery) -> [WeightedAcuityPlanProposal] {
        return query.apply(store.list())
    }
}
