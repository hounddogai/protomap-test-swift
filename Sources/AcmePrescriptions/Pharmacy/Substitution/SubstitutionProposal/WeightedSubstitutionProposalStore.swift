import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted substitution proposals by code.
    protocol WeightedSubstitutionProposalStore {
        func find(_ code: String) -> WeightedSubstitutionProposal?
        func save(_ item: WeightedSubstitutionProposal)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSubstitutionProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSubstitutionProposalStore: WeightedSubstitutionProposalStore {
        var items: [String: WeightedSubstitutionProposal]
        var order: [String]

        init(items: [String: WeightedSubstitutionProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSubstitutionProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSubstitutionProposal) {
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

        func list() -> [WeightedSubstitutionProposal] {
            var out: [WeightedSubstitutionProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSubstitutionProposalStore() -> any WeightedSubstitutionProposalStore {
        return MemoryWeightedSubstitutionProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSubstitutionProposalStore: WeightedSubstitutionProposalStore {
        var inner: MemoryWeightedSubstitutionProposalStore
        var cache: TTLCache<WeightedSubstitutionProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSubstitutionProposalStore, cache: TTLCache<WeightedSubstitutionProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSubstitutionProposal? {
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

        func save(_ item: WeightedSubstitutionProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSubstitutionProposal] {
            return inner.list()
        }
    }

    static func newCachedWeightedSubstitutionProposalStore(_ inner: MemoryWeightedSubstitutionProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSubstitutionProposalStore {
        return CachedWeightedSubstitutionProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted substitution proposals. Empty fields match all.
    final class WeightedSubstitutionProposalQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSubstitutionProposal) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [WeightedSubstitutionProposal]) -> [WeightedSubstitutionProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSubstitutionProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSubstitutionProposals(_ store: any WeightedSubstitutionProposalStore, query: WeightedSubstitutionProposalQuery) -> [WeightedSubstitutionProposal] {
        return query.apply(store.list())
    }
}
