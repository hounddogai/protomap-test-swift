import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual acuity plan proposals by code.
    protocol ManualAcuityPlanProposalStore {
        func find(_ code: String) -> ManualAcuityPlanProposal?
        func save(_ item: ManualAcuityPlanProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ManualAcuityPlanProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualAcuityPlanProposalStore: ManualAcuityPlanProposalStore {
        var items: [String: ManualAcuityPlanProposal]
        var order: [String]

        init(items: [String: ManualAcuityPlanProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualAcuityPlanProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualAcuityPlanProposal) {
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

        func list() -> [ManualAcuityPlanProposal] {
            var out: [ManualAcuityPlanProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualAcuityPlanProposalStore() -> any ManualAcuityPlanProposalStore {
        return MemoryManualAcuityPlanProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualAcuityPlanProposalStore: ManualAcuityPlanProposalStore {
        var inner: MemoryManualAcuityPlanProposalStore
        var cache: TTLCache<ManualAcuityPlanProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualAcuityPlanProposalStore, cache: TTLCache<ManualAcuityPlanProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualAcuityPlanProposal? {
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

        func save(_ item: ManualAcuityPlanProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualAcuityPlanProposal] {
            return inner.list()
        }
    }

    static func newCachedManualAcuityPlanProposalStore(_ inner: MemoryManualAcuityPlanProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualAcuityPlanProposalStore {
        return CachedManualAcuityPlanProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual acuity plan proposals. Empty fields match all.
    final class ManualAcuityPlanProposalQuery {
        var locale: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualAcuityPlanProposal) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [ManualAcuityPlanProposal]) -> [ManualAcuityPlanProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualAcuityPlanProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualAcuityPlanProposals(_ store: any ManualAcuityPlanProposalStore, query: ManualAcuityPlanProposalQuery) -> [ManualAcuityPlanProposal] {
        return query.apply(store.list())
    }
}
