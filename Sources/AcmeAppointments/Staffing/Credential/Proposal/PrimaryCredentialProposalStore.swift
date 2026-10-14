import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary credential proposals by code.
    protocol PrimaryCredentialProposalStore {
        func find(_ code: String) -> PrimaryCredentialProposal?
        func save(_ item: PrimaryCredentialProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCredentialProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCredentialProposalStore: PrimaryCredentialProposalStore {
        var items: [String: PrimaryCredentialProposal]
        var order: [String]

        init(items: [String: PrimaryCredentialProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCredentialProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCredentialProposal) {
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

        func list() -> [PrimaryCredentialProposal] {
            var out: [PrimaryCredentialProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCredentialProposalStore() -> any PrimaryCredentialProposalStore {
        return MemoryPrimaryCredentialProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCredentialProposalStore: PrimaryCredentialProposalStore {
        var inner: MemoryPrimaryCredentialProposalStore
        var cache: TTLCache<PrimaryCredentialProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCredentialProposalStore, cache: TTLCache<PrimaryCredentialProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCredentialProposal? {
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

        func save(_ item: PrimaryCredentialProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCredentialProposal] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCredentialProposalStore(_ inner: MemoryPrimaryCredentialProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCredentialProposalStore {
        return CachedPrimaryCredentialProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary credential proposals. Empty fields match all.
    final class PrimaryCredentialProposalQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCredentialProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCredentialProposal]) -> [PrimaryCredentialProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCredentialProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCredentialProposals(_ store: any PrimaryCredentialProposalStore, query: PrimaryCredentialProposalQuery) -> [PrimaryCredentialProposal] {
        return query.apply(store.list())
    }
}
