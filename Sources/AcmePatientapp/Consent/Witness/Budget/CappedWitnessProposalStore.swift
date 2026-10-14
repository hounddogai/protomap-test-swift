import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped witness proposals by code.
    protocol CappedWitnessProposalStore {
        func find(_ code: String) -> CappedWitnessProposal?
        func save(_ item: CappedWitnessProposal)
        func remove(_ code: String) -> Bool
        func list() -> [CappedWitnessProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedWitnessProposalStore: CappedWitnessProposalStore {
        var items: [String: CappedWitnessProposal]
        var order: [String]

        init(items: [String: CappedWitnessProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedWitnessProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedWitnessProposal) {
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

        func list() -> [CappedWitnessProposal] {
            var out: [CappedWitnessProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedWitnessProposalStore() -> any CappedWitnessProposalStore {
        return MemoryCappedWitnessProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedWitnessProposalStore: CappedWitnessProposalStore {
        var inner: MemoryCappedWitnessProposalStore
        var cache: TTLCache<CappedWitnessProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedWitnessProposalStore, cache: TTLCache<CappedWitnessProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedWitnessProposal? {
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

        func save(_ item: CappedWitnessProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedWitnessProposal] {
            return inner.list()
        }
    }

    static func newCachedCappedWitnessProposalStore(_ inner: MemoryCappedWitnessProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedWitnessProposalStore {
        return CachedCappedWitnessProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped witness proposals. Empty fields match all.
    final class CappedWitnessProposalQuery {
        var unit: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedWitnessProposal) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedWitnessProposal]) -> [CappedWitnessProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedWitnessProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedWitnessProposals(_ store: any CappedWitnessProposalStore, query: CappedWitnessProposalQuery) -> [CappedWitnessProposal] {
        return query.apply(store.list())
    }
}
