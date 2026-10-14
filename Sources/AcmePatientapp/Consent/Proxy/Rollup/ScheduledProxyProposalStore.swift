import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled proxy proposals by code.
    protocol ScheduledProxyProposalStore {
        func find(_ code: String) -> ScheduledProxyProposal?
        func save(_ item: ScheduledProxyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledProxyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledProxyProposalStore: ScheduledProxyProposalStore {
        var items: [String: ScheduledProxyProposal]
        var order: [String]

        init(items: [String: ScheduledProxyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledProxyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledProxyProposal) {
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

        func list() -> [ScheduledProxyProposal] {
            var out: [ScheduledProxyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledProxyProposalStore() -> any ScheduledProxyProposalStore {
        return MemoryScheduledProxyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledProxyProposalStore: ScheduledProxyProposalStore {
        var inner: MemoryScheduledProxyProposalStore
        var cache: TTLCache<ScheduledProxyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledProxyProposalStore, cache: TTLCache<ScheduledProxyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledProxyProposal? {
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

        func save(_ item: ScheduledProxyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledProxyProposal] {
            return inner.list()
        }
    }

    static func newCachedScheduledProxyProposalStore(_ inner: MemoryScheduledProxyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledProxyProposalStore {
        return CachedScheduledProxyProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled proxy proposals. Empty fields match all.
    final class ScheduledProxyProposalQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledProxyProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledProxyProposal]) -> [ScheduledProxyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledProxyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledProxyProposals(_ store: any ScheduledProxyProposalStore, query: ScheduledProxyProposalQuery) -> [ScheduledProxyProposal] {
        return query.apply(store.list())
    }
}
