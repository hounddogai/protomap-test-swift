import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled witness proposals by code.
    protocol ScheduledWitnessProposalStore {
        func find(_ code: String) -> ScheduledWitnessProposal?
        func save(_ item: ScheduledWitnessProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledWitnessProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledWitnessProposalStore: ScheduledWitnessProposalStore {
        var items: [String: ScheduledWitnessProposal]
        var order: [String]

        init(items: [String: ScheduledWitnessProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledWitnessProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledWitnessProposal) {
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

        func list() -> [ScheduledWitnessProposal] {
            var out: [ScheduledWitnessProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledWitnessProposalStore() -> any ScheduledWitnessProposalStore {
        return MemoryScheduledWitnessProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledWitnessProposalStore: ScheduledWitnessProposalStore {
        var inner: MemoryScheduledWitnessProposalStore
        var cache: TTLCache<ScheduledWitnessProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledWitnessProposalStore, cache: TTLCache<ScheduledWitnessProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledWitnessProposal? {
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

        func save(_ item: ScheduledWitnessProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledWitnessProposal] {
            return inner.list()
        }
    }

    static func newCachedScheduledWitnessProposalStore(_ inner: MemoryScheduledWitnessProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledWitnessProposalStore {
        return CachedScheduledWitnessProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled witness proposals. Empty fields match all.
    final class ScheduledWitnessProposalQuery {
        var source: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMargin: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledWitnessProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledWitnessProposal]) -> [ScheduledWitnessProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledWitnessProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledWitnessProposals(_ store: any ScheduledWitnessProposalStore, query: ScheduledWitnessProposalQuery) -> [ScheduledWitnessProposal] {
        return query.apply(store.list())
    }
}
