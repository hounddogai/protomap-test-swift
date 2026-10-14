import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up proposals by code.
    protocol FollowUpProposalStore {
        func find(_ code: String) -> FollowUpProposal?
        func save(_ item: FollowUpProposal)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpProposalStore: FollowUpProposalStore {
        var items: [String: FollowUpProposal]
        var order: [String]

        init(items: [String: FollowUpProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpProposal) {
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

        func list() -> [FollowUpProposal] {
            var out: [FollowUpProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpProposalStore() -> any FollowUpProposalStore {
        return MemoryFollowUpProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpProposalStore: FollowUpProposalStore {
        var inner: MemoryFollowUpProposalStore
        var cache: TTLCache<FollowUpProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpProposalStore, cache: TTLCache<FollowUpProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpProposal? {
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

        func save(_ item: FollowUpProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpProposal] {
            return inner.list()
        }
    }

    static func newCachedFollowUpProposalStore(_ inner: MemoryFollowUpProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpProposalStore {
        return CachedFollowUpProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up proposals. Empty fields match all.
    final class FollowUpProposalQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpProposal]) -> [FollowUpProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpProposals(_ store: any FollowUpProposalStore, query: FollowUpProposalQuery) -> [FollowUpProposal] {
        return query.apply(store.list())
    }
}
