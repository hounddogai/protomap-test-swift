import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan proposals by code.
    protocol AcuityPlanProposalStore {
        func find(_ code: String) -> AcuityPlanProposal?
        func save(_ item: AcuityPlanProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanProposalStore: AcuityPlanProposalStore {
        var items: [String: AcuityPlanProposal]
        var order: [String]

        init(items: [String: AcuityPlanProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanProposal) {
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

        func list() -> [AcuityPlanProposal] {
            var out: [AcuityPlanProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanProposalStore() -> any AcuityPlanProposalStore {
        return MemoryAcuityPlanProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanProposalStore: AcuityPlanProposalStore {
        var inner: MemoryAcuityPlanProposalStore
        var cache: TTLCache<AcuityPlanProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanProposalStore, cache: TTLCache<AcuityPlanProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanProposal? {
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

        func save(_ item: AcuityPlanProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanProposal] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanProposalStore(_ inner: MemoryAcuityPlanProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanProposalStore {
        return CachedAcuityPlanProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan proposals. Empty fields match all.
    final class AcuityPlanProposalQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanProposal]) -> [AcuityPlanProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanProposals(_ store: any AcuityPlanProposalStore, query: AcuityPlanProposalQuery) -> [AcuityPlanProposal] {
        return query.apply(store.list())
    }
}
