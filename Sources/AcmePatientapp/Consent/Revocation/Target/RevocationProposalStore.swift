import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation proposals by code.
    protocol RevocationProposalStore {
        func find(_ code: String) -> RevocationProposal?
        func save(_ item: RevocationProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationProposalStore: RevocationProposalStore {
        var items: [String: RevocationProposal]
        var order: [String]

        init(items: [String: RevocationProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationProposal) {
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

        func list() -> [RevocationProposal] {
            var out: [RevocationProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationProposalStore() -> any RevocationProposalStore {
        return MemoryRevocationProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationProposalStore: RevocationProposalStore {
        var inner: MemoryRevocationProposalStore
        var cache: TTLCache<RevocationProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationProposalStore, cache: TTLCache<RevocationProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationProposal? {
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

        func save(_ item: RevocationProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationProposal] {
            return inner.list()
        }
    }

    static func newCachedRevocationProposalStore(_ inner: MemoryRevocationProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationProposalStore {
        return CachedRevocationProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation proposals. Empty fields match all.
    final class RevocationProposalQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationProposal]) -> [RevocationProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationProposals(_ store: any RevocationProposalStore, query: RevocationProposalQuery) -> [RevocationProposal] {
        return query.apply(store.list())
    }
}
