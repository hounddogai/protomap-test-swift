import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim proposals by code.
    protocol ClaimProposalStore {
        func find(_ code: String) -> ClaimProposal?
        func save(_ item: ClaimProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimProposalStore: ClaimProposalStore {
        var items: [String: ClaimProposal]
        var order: [String]

        init(items: [String: ClaimProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimProposal) {
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

        func list() -> [ClaimProposal] {
            var out: [ClaimProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimProposalStore() -> any ClaimProposalStore {
        return MemoryClaimProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimProposalStore: ClaimProposalStore {
        var inner: MemoryClaimProposalStore
        var cache: TTLCache<ClaimProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimProposalStore, cache: TTLCache<ClaimProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimProposal? {
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

        func save(_ item: ClaimProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimProposal] {
            return inner.list()
        }
    }

    static func newCachedClaimProposalStore(_ inner: MemoryClaimProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimProposalStore {
        return CachedClaimProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim proposals. Empty fields match all.
    final class ClaimProposalQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ClaimProposal]) -> [ClaimProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimProposals(_ store: any ClaimProposalStore, query: ClaimProposalQuery) -> [ClaimProposal] {
        return query.apply(store.list())
    }
}
