import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending charge proposals by code.
    protocol PendingChargeProposalStore {
        func find(_ code: String) -> PendingChargeProposal?
        func save(_ item: PendingChargeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [PendingChargeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingChargeProposalStore: PendingChargeProposalStore {
        var items: [String: PendingChargeProposal]
        var order: [String]

        init(items: [String: PendingChargeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingChargeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingChargeProposal) {
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

        func list() -> [PendingChargeProposal] {
            var out: [PendingChargeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingChargeProposalStore() -> any PendingChargeProposalStore {
        return MemoryPendingChargeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingChargeProposalStore: PendingChargeProposalStore {
        var inner: MemoryPendingChargeProposalStore
        var cache: TTLCache<PendingChargeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingChargeProposalStore, cache: TTLCache<PendingChargeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingChargeProposal? {
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

        func save(_ item: PendingChargeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingChargeProposal] {
            return inner.list()
        }
    }

    static func newCachedPendingChargeProposalStore(_ inner: MemoryPendingChargeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingChargeProposalStore {
        return CachedPendingChargeProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending charge proposals. Empty fields match all.
    final class PendingChargeProposalQuery {
        var channel: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRatio: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingChargeProposal) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingChargeProposal]) -> [PendingChargeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingChargeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingChargeProposals(_ store: any PendingChargeProposalStore, query: PendingChargeProposalQuery) -> [PendingChargeProposal] {
        return query.apply(store.list())
    }
}
