import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization proposals by code.
    protocol AuthorizationProposalStore {
        func find(_ code: String) -> AuthorizationProposal?
        func save(_ item: AuthorizationProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationProposalStore: AuthorizationProposalStore {
        var items: [String: AuthorizationProposal]
        var order: [String]

        init(items: [String: AuthorizationProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationProposal) {
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

        func list() -> [AuthorizationProposal] {
            var out: [AuthorizationProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationProposalStore() -> any AuthorizationProposalStore {
        return MemoryAuthorizationProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationProposalStore: AuthorizationProposalStore {
        var inner: MemoryAuthorizationProposalStore
        var cache: TTLCache<AuthorizationProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationProposalStore, cache: TTLCache<AuthorizationProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationProposal? {
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

        func save(_ item: AuthorizationProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationProposal] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationProposalStore(_ inner: MemoryAuthorizationProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationProposalStore {
        return CachedAuthorizationProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization proposals. Empty fields match all.
    final class AuthorizationProposalQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationProposal]) -> [AuthorizationProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationProposals(_ store: any AuthorizationProposalStore, query: AuthorizationProposalQuery) -> [AuthorizationProposal] {
        return query.apply(store.list())
    }
}
