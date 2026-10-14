import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary outreach proposals by code.
    protocol PrimaryOutreachProposalStore {
        func find(_ code: String) -> PrimaryOutreachProposal?
        func save(_ item: PrimaryOutreachProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOutreachProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOutreachProposalStore: PrimaryOutreachProposalStore {
        var items: [String: PrimaryOutreachProposal]
        var order: [String]

        init(items: [String: PrimaryOutreachProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOutreachProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOutreachProposal) {
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

        func list() -> [PrimaryOutreachProposal] {
            var out: [PrimaryOutreachProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOutreachProposalStore() -> any PrimaryOutreachProposalStore {
        return MemoryPrimaryOutreachProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOutreachProposalStore: PrimaryOutreachProposalStore {
        var inner: MemoryPrimaryOutreachProposalStore
        var cache: TTLCache<PrimaryOutreachProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOutreachProposalStore, cache: TTLCache<PrimaryOutreachProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOutreachProposal? {
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

        func save(_ item: PrimaryOutreachProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOutreachProposal] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOutreachProposalStore(_ inner: MemoryPrimaryOutreachProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOutreachProposalStore {
        return CachedPrimaryOutreachProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary outreach proposals. Empty fields match all.
    final class PrimaryOutreachProposalQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOutreachProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryOutreachProposal]) -> [PrimaryOutreachProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOutreachProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOutreachProposals(_ store: any PrimaryOutreachProposalStore, query: PrimaryOutreachProposalQuery) -> [PrimaryOutreachProposal] {
        return query.apply(store.list())
    }
}
