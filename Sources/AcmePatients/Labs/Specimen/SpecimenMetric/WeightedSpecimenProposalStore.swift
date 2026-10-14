import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted specimen proposals by code.
    protocol WeightedSpecimenProposalStore {
        func find(_ code: String) -> WeightedSpecimenProposal?
        func save(_ item: WeightedSpecimenProposal)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSpecimenProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSpecimenProposalStore: WeightedSpecimenProposalStore {
        var items: [String: WeightedSpecimenProposal]
        var order: [String]

        init(items: [String: WeightedSpecimenProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSpecimenProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSpecimenProposal) {
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

        func list() -> [WeightedSpecimenProposal] {
            var out: [WeightedSpecimenProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSpecimenProposalStore() -> any WeightedSpecimenProposalStore {
        return MemoryWeightedSpecimenProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSpecimenProposalStore: WeightedSpecimenProposalStore {
        var inner: MemoryWeightedSpecimenProposalStore
        var cache: TTLCache<WeightedSpecimenProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSpecimenProposalStore, cache: TTLCache<WeightedSpecimenProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSpecimenProposal? {
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

        func save(_ item: WeightedSpecimenProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSpecimenProposal] {
            return inner.list()
        }
    }

    static func newCachedWeightedSpecimenProposalStore(_ inner: MemoryWeightedSpecimenProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSpecimenProposalStore {
        return CachedWeightedSpecimenProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted specimen proposals. Empty fields match all.
    final class WeightedSpecimenProposalQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSpecimenProposal) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [WeightedSpecimenProposal]) -> [WeightedSpecimenProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSpecimenProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSpecimenProposals(_ store: any WeightedSpecimenProposalStore, query: WeightedSpecimenProposalQuery) -> [WeightedSpecimenProposal] {
        return query.apply(store.list())
    }
}
