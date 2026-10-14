import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling transfer proposals by code.
    protocol RollingTransferProposalStore {
        func find(_ code: String) -> RollingTransferProposal?
        func save(_ item: RollingTransferProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RollingTransferProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingTransferProposalStore: RollingTransferProposalStore {
        var items: [String: RollingTransferProposal]
        var order: [String]

        init(items: [String: RollingTransferProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingTransferProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingTransferProposal) {
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

        func list() -> [RollingTransferProposal] {
            var out: [RollingTransferProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingTransferProposalStore() -> any RollingTransferProposalStore {
        return MemoryRollingTransferProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingTransferProposalStore: RollingTransferProposalStore {
        var inner: MemoryRollingTransferProposalStore
        var cache: TTLCache<RollingTransferProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingTransferProposalStore, cache: TTLCache<RollingTransferProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingTransferProposal? {
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

        func save(_ item: RollingTransferProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingTransferProposal] {
            return inner.list()
        }
    }

    static func newCachedRollingTransferProposalStore(_ inner: MemoryRollingTransferProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingTransferProposalStore {
        return CachedRollingTransferProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling transfer proposals. Empty fields match all.
    final class RollingTransferProposalQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingTransferProposal) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingTransferProposal]) -> [RollingTransferProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingTransferProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingTransferProposals(_ store: any RollingTransferProposalStore, query: RollingTransferProposalQuery) -> [RollingTransferProposal] {
        return query.apply(store.list())
    }
}
