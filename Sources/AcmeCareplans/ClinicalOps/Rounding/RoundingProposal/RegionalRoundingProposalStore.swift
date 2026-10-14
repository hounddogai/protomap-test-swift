import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional rounding proposals by code.
    protocol RegionalRoundingProposalStore {
        func find(_ code: String) -> RegionalRoundingProposal?
        func save(_ item: RegionalRoundingProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRoundingProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRoundingProposalStore: RegionalRoundingProposalStore {
        var items: [String: RegionalRoundingProposal]
        var order: [String]

        init(items: [String: RegionalRoundingProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRoundingProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRoundingProposal) {
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

        func list() -> [RegionalRoundingProposal] {
            var out: [RegionalRoundingProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRoundingProposalStore() -> any RegionalRoundingProposalStore {
        return MemoryRegionalRoundingProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRoundingProposalStore: RegionalRoundingProposalStore {
        var inner: MemoryRegionalRoundingProposalStore
        var cache: TTLCache<RegionalRoundingProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRoundingProposalStore, cache: TTLCache<RegionalRoundingProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRoundingProposal? {
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

        func save(_ item: RegionalRoundingProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRoundingProposal] {
            return inner.list()
        }
    }

    static func newCachedRegionalRoundingProposalStore(_ inner: MemoryRegionalRoundingProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRoundingProposalStore {
        return CachedRegionalRoundingProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional rounding proposals. Empty fields match all.
    final class RegionalRoundingProposalQuery {
        var region: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRoundingProposal) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRoundingProposal]) -> [RegionalRoundingProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRoundingProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRoundingProposals(_ store: any RegionalRoundingProposalStore, query: RegionalRoundingProposalQuery) -> [RegionalRoundingProposal] {
        return query.apply(store.list())
    }
}
