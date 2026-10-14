import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict substitution proposals by code.
    protocol StrictSubstitutionProposalStore {
        func find(_ code: String) -> StrictSubstitutionProposal?
        func save(_ item: StrictSubstitutionProposal)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSubstitutionProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSubstitutionProposalStore: StrictSubstitutionProposalStore {
        var items: [String: StrictSubstitutionProposal]
        var order: [String]

        init(items: [String: StrictSubstitutionProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSubstitutionProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSubstitutionProposal) {
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

        func list() -> [StrictSubstitutionProposal] {
            var out: [StrictSubstitutionProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSubstitutionProposalStore() -> any StrictSubstitutionProposalStore {
        return MemoryStrictSubstitutionProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSubstitutionProposalStore: StrictSubstitutionProposalStore {
        var inner: MemoryStrictSubstitutionProposalStore
        var cache: TTLCache<StrictSubstitutionProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSubstitutionProposalStore, cache: TTLCache<StrictSubstitutionProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSubstitutionProposal? {
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

        func save(_ item: StrictSubstitutionProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSubstitutionProposal] {
            return inner.list()
        }
    }

    static func newCachedStrictSubstitutionProposalStore(_ inner: MemoryStrictSubstitutionProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSubstitutionProposalStore {
        return CachedStrictSubstitutionProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict substitution proposals. Empty fields match all.
    final class StrictSubstitutionProposalQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSubstitutionProposal) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSubstitutionProposal]) -> [StrictSubstitutionProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSubstitutionProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSubstitutionProposals(_ store: any StrictSubstitutionProposalStore, query: StrictSubstitutionProposalQuery) -> [StrictSubstitutionProposal] {
        return query.apply(store.list())
    }
}
