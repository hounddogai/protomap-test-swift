import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement proposals by code.
    protocol StatementProposalStore {
        func find(_ code: String) -> StatementProposal?
        func save(_ item: StatementProposal)
        func remove(_ code: String) -> Bool
        func list() -> [StatementProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementProposalStore: StatementProposalStore {
        var items: [String: StatementProposal]
        var order: [String]

        init(items: [String: StatementProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementProposal) {
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

        func list() -> [StatementProposal] {
            var out: [StatementProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementProposalStore() -> any StatementProposalStore {
        return MemoryStatementProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementProposalStore: StatementProposalStore {
        var inner: MemoryStatementProposalStore
        var cache: TTLCache<StatementProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementProposalStore, cache: TTLCache<StatementProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementProposal? {
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

        func save(_ item: StatementProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementProposal] {
            return inner.list()
        }
    }

    static func newCachedStatementProposalStore(_ inner: MemoryStatementProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementProposalStore {
        return CachedStatementProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement proposals. Empty fields match all.
    final class StatementProposalQuery {
        var channel: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementProposal) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementProposal]) -> [StatementProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementProposals(_ store: any StatementProposalStore, query: StatementProposalQuery) -> [StatementProposal] {
        return query.apply(store.list())
    }
}
