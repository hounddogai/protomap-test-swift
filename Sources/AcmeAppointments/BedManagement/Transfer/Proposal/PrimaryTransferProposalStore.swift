import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary transfer proposals by code.
    protocol PrimaryTransferProposalStore {
        func find(_ code: String) -> PrimaryTransferProposal?
        func save(_ item: PrimaryTransferProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryTransferProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryTransferProposalStore: PrimaryTransferProposalStore {
        var items: [String: PrimaryTransferProposal]
        var order: [String]

        init(items: [String: PrimaryTransferProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryTransferProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryTransferProposal) {
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

        func list() -> [PrimaryTransferProposal] {
            var out: [PrimaryTransferProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryTransferProposalStore() -> any PrimaryTransferProposalStore {
        return MemoryPrimaryTransferProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryTransferProposalStore: PrimaryTransferProposalStore {
        var inner: MemoryPrimaryTransferProposalStore
        var cache: TTLCache<PrimaryTransferProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryTransferProposalStore, cache: TTLCache<PrimaryTransferProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryTransferProposal? {
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

        func save(_ item: PrimaryTransferProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryTransferProposal] {
            return inner.list()
        }
    }

    static func newCachedPrimaryTransferProposalStore(_ inner: MemoryPrimaryTransferProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryTransferProposalStore {
        return CachedPrimaryTransferProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary transfer proposals. Empty fields match all.
    final class PrimaryTransferProposalQuery {
        var source: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryTransferProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryTransferProposal]) -> [PrimaryTransferProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryTransferProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryTransferProposals(_ store: any PrimaryTransferProposalStore, query: PrimaryTransferProposalQuery) -> [PrimaryTransferProposal] {
        return query.apply(store.list())
    }
}
