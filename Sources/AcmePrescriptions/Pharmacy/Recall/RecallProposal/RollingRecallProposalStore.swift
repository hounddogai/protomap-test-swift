import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling recall proposals by code.
    protocol RollingRecallProposalStore {
        func find(_ code: String) -> RollingRecallProposal?
        func save(_ item: RollingRecallProposal)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRecallProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRecallProposalStore: RollingRecallProposalStore {
        var items: [String: RollingRecallProposal]
        var order: [String]

        init(items: [String: RollingRecallProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRecallProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRecallProposal) {
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

        func list() -> [RollingRecallProposal] {
            var out: [RollingRecallProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRecallProposalStore() -> any RollingRecallProposalStore {
        return MemoryRollingRecallProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRecallProposalStore: RollingRecallProposalStore {
        var inner: MemoryRollingRecallProposalStore
        var cache: TTLCache<RollingRecallProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRecallProposalStore, cache: TTLCache<RollingRecallProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRecallProposal? {
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

        func save(_ item: RollingRecallProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRecallProposal] {
            return inner.list()
        }
    }

    static func newCachedRollingRecallProposalStore(_ inner: MemoryRollingRecallProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRecallProposalStore {
        return CachedRollingRecallProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling recall proposals. Empty fields match all.
    final class RollingRecallProposalQuery {
        var region: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRecallProposal) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRecallProposal]) -> [RollingRecallProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRecallProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRecallProposals(_ store: any RollingRecallProposalStore, query: RollingRecallProposalQuery) -> [RollingRecallProposal] {
        return query.apply(store.list())
    }
}
