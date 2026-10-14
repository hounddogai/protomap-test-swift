import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled overtime proposals by code.
    protocol ScheduledOvertimeProposalStore {
        func find(_ code: String) -> ScheduledOvertimeProposal?
        func save(_ item: ScheduledOvertimeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledOvertimeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledOvertimeProposalStore: ScheduledOvertimeProposalStore {
        var items: [String: ScheduledOvertimeProposal]
        var order: [String]

        init(items: [String: ScheduledOvertimeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledOvertimeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledOvertimeProposal) {
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

        func list() -> [ScheduledOvertimeProposal] {
            var out: [ScheduledOvertimeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledOvertimeProposalStore() -> any ScheduledOvertimeProposalStore {
        return MemoryScheduledOvertimeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledOvertimeProposalStore: ScheduledOvertimeProposalStore {
        var inner: MemoryScheduledOvertimeProposalStore
        var cache: TTLCache<ScheduledOvertimeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledOvertimeProposalStore, cache: TTLCache<ScheduledOvertimeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledOvertimeProposal? {
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

        func save(_ item: ScheduledOvertimeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledOvertimeProposal] {
            return inner.list()
        }
    }

    static func newCachedScheduledOvertimeProposalStore(_ inner: MemoryScheduledOvertimeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledOvertimeProposalStore {
        return CachedScheduledOvertimeProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled overtime proposals. Empty fields match all.
    final class ScheduledOvertimeProposalQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledOvertimeProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledOvertimeProposal]) -> [ScheduledOvertimeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledOvertimeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledOvertimeProposals(_ store: any ScheduledOvertimeProposalStore, query: ScheduledOvertimeProposalQuery) -> [ScheduledOvertimeProposal] {
        return query.apply(store.list())
    }
}
