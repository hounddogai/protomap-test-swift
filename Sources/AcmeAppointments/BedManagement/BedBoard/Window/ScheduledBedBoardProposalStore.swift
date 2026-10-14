import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled bed board proposals by code.
    protocol ScheduledBedBoardProposalStore {
        func find(_ code: String) -> ScheduledBedBoardProposal?
        func save(_ item: ScheduledBedBoardProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledBedBoardProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledBedBoardProposalStore: ScheduledBedBoardProposalStore {
        var items: [String: ScheduledBedBoardProposal]
        var order: [String]

        init(items: [String: ScheduledBedBoardProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledBedBoardProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledBedBoardProposal) {
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

        func list() -> [ScheduledBedBoardProposal] {
            var out: [ScheduledBedBoardProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledBedBoardProposalStore() -> any ScheduledBedBoardProposalStore {
        return MemoryScheduledBedBoardProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledBedBoardProposalStore: ScheduledBedBoardProposalStore {
        var inner: MemoryScheduledBedBoardProposalStore
        var cache: TTLCache<ScheduledBedBoardProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledBedBoardProposalStore, cache: TTLCache<ScheduledBedBoardProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledBedBoardProposal? {
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

        func save(_ item: ScheduledBedBoardProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledBedBoardProposal] {
            return inner.list()
        }
    }

    static func newCachedScheduledBedBoardProposalStore(_ inner: MemoryScheduledBedBoardProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledBedBoardProposalStore {
        return CachedScheduledBedBoardProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled bed board proposals. Empty fields match all.
    final class ScheduledBedBoardProposalQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledBedBoardProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledBedBoardProposal]) -> [ScheduledBedBoardProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledBedBoardProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledBedBoardProposals(_ store: any ScheduledBedBoardProposalStore, query: ScheduledBedBoardProposalQuery) -> [ScheduledBedBoardProposal] {
        return query.apply(store.list())
    }
}
