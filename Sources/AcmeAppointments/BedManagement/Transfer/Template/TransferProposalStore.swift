import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer proposals by code.
    protocol TransferProposalStore {
        func find(_ code: String) -> TransferProposal?
        func save(_ item: TransferProposal)
        func remove(_ code: String) -> Bool
        func list() -> [TransferProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferProposalStore: TransferProposalStore {
        var items: [String: TransferProposal]
        var order: [String]

        init(items: [String: TransferProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferProposal) {
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

        func list() -> [TransferProposal] {
            var out: [TransferProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferProposalStore() -> any TransferProposalStore {
        return MemoryTransferProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferProposalStore: TransferProposalStore {
        var inner: MemoryTransferProposalStore
        var cache: TTLCache<TransferProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferProposalStore, cache: TTLCache<TransferProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferProposal? {
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

        func save(_ item: TransferProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferProposal] {
            return inner.list()
        }
    }

    static func newCachedTransferProposalStore(_ inner: MemoryTransferProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferProposalStore {
        return CachedTransferProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer proposals. Empty fields match all.
    final class TransferProposalQuery {
        var source: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minBudget: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferProposal]) -> [TransferProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferProposals(_ store: any TransferProposalStore, query: TransferProposalQuery) -> [TransferProposal] {
        return query.apply(store.list())
    }
}
