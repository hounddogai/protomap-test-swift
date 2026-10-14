import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending statement proposals by code.
    protocol PendingStatementProposalStore {
        func find(_ code: String) -> PendingStatementProposal?
        func save(_ item: PendingStatementProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PendingStatementProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingStatementProposalStore: PendingStatementProposalStore {
        var items: [String: PendingStatementProposal]
        var order: [String]

        init(items: [String: PendingStatementProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingStatementProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingStatementProposal) {
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

        func list() -> [PendingStatementProposal] {
            var out: [PendingStatementProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingStatementProposalStore() -> any PendingStatementProposalStore {
        return MemoryPendingStatementProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingStatementProposalStore: PendingStatementProposalStore {
        var inner: MemoryPendingStatementProposalStore
        var cache: TTLCache<PendingStatementProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingStatementProposalStore, cache: TTLCache<PendingStatementProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingStatementProposal? {
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

        func save(_ item: PendingStatementProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingStatementProposal] {
            return inner.list()
        }
    }

    static func newCachedPendingStatementProposalStore(_ inner: MemoryPendingStatementProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingStatementProposalStore {
        return CachedPendingStatementProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending statement proposals. Empty fields match all.
    final class PendingStatementProposalQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingStatementProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingStatementProposal]) -> [PendingStatementProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingStatementProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingStatementProposals(_ store: any PendingStatementProposalStore, query: PendingStatementProposalQuery) -> [PendingStatementProposal] {
        return query.apply(store.list())
    }
}
