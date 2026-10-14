import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan proposals by code.
    protocol DischargePlanProposalStore {
        func find(_ code: String) -> DischargePlanProposal?
        func save(_ item: DischargePlanProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanProposalStore: DischargePlanProposalStore {
        var items: [String: DischargePlanProposal]
        var order: [String]

        init(items: [String: DischargePlanProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanProposal) {
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

        func list() -> [DischargePlanProposal] {
            var out: [DischargePlanProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanProposalStore() -> any DischargePlanProposalStore {
        return MemoryDischargePlanProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanProposalStore: DischargePlanProposalStore {
        var inner: MemoryDischargePlanProposalStore
        var cache: TTLCache<DischargePlanProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanProposalStore, cache: TTLCache<DischargePlanProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanProposal? {
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

        func save(_ item: DischargePlanProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanProposal] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanProposalStore(_ inner: MemoryDischargePlanProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanProposalStore {
        return CachedDischargePlanProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan proposals. Empty fields match all.
    final class DischargePlanProposalQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanProposal]) -> [DischargePlanProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanProposals(_ store: any DischargePlanProposalStore, query: DischargePlanProposalQuery) -> [DischargePlanProposal] {
        return query.apply(store.list())
    }
}
