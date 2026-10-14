import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census proposals by code.
    protocol CensusProposalStore {
        func find(_ code: String) -> CensusProposal?
        func save(_ item: CensusProposal)
        func remove(_ code: String) -> Bool
        func list() -> [CensusProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusProposalStore: CensusProposalStore {
        var items: [String: CensusProposal]
        var order: [String]

        init(items: [String: CensusProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusProposal) {
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

        func list() -> [CensusProposal] {
            var out: [CensusProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusProposalStore() -> any CensusProposalStore {
        return MemoryCensusProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusProposalStore: CensusProposalStore {
        var inner: MemoryCensusProposalStore
        var cache: TTLCache<CensusProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusProposalStore, cache: TTLCache<CensusProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusProposal? {
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

        func save(_ item: CensusProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusProposal] {
            return inner.list()
        }
    }

    static func newCachedCensusProposalStore(_ inner: MemoryCensusProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusProposalStore {
        return CachedCensusProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census proposals. Empty fields match all.
    final class CensusProposalQuery {
        var country: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusProposal) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusProposal]) -> [CensusProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusProposals(_ store: any CensusProposalStore, query: CensusProposalQuery) -> [CensusProposal] {
        return query.apply(store.list())
    }
}
