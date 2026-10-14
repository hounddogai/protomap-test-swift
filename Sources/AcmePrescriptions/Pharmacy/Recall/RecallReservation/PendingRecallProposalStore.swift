import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall proposals by code.
    protocol PendingRecallProposalStore {
        func find(_ code: String) -> PendingRecallProposal?
        func save(_ item: PendingRecallProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallProposalStore: PendingRecallProposalStore {
        var items: [String: PendingRecallProposal]
        var order: [String]

        init(items: [String: PendingRecallProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallProposal) {
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

        func list() -> [PendingRecallProposal] {
            var out: [PendingRecallProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallProposalStore() -> any PendingRecallProposalStore {
        return MemoryPendingRecallProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallProposalStore: PendingRecallProposalStore {
        var inner: MemoryPendingRecallProposalStore
        var cache: TTLCache<PendingRecallProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallProposalStore, cache: TTLCache<PendingRecallProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallProposal? {
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

        func save(_ item: PendingRecallProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallProposal] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallProposalStore(_ inner: MemoryPendingRecallProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallProposalStore {
        return CachedPendingRecallProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall proposals. Empty fields match all.
    final class PendingRecallProposalQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallProposal) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRecallProposal]) -> [PendingRecallProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallProposals(_ store: any PendingRecallProposalStore, query: PendingRecallProposalQuery) -> [PendingRecallProposal] {
        return query.apply(store.list())
    }
}
