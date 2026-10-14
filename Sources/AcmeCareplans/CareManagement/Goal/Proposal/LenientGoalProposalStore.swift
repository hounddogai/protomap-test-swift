import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient goal proposals by code.
    protocol LenientGoalProposalStore {
        func find(_ code: String) -> LenientGoalProposal?
        func save(_ item: LenientGoalProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LenientGoalProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientGoalProposalStore: LenientGoalProposalStore {
        var items: [String: LenientGoalProposal]
        var order: [String]

        init(items: [String: LenientGoalProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientGoalProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientGoalProposal) {
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

        func list() -> [LenientGoalProposal] {
            var out: [LenientGoalProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientGoalProposalStore() -> any LenientGoalProposalStore {
        return MemoryLenientGoalProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientGoalProposalStore: LenientGoalProposalStore {
        var inner: MemoryLenientGoalProposalStore
        var cache: TTLCache<LenientGoalProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientGoalProposalStore, cache: TTLCache<LenientGoalProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientGoalProposal? {
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

        func save(_ item: LenientGoalProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientGoalProposal] {
            return inner.list()
        }
    }

    static func newCachedLenientGoalProposalStore(_ inner: MemoryLenientGoalProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientGoalProposalStore {
        return CachedLenientGoalProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient goal proposals. Empty fields match all.
    final class LenientGoalProposalQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientGoalProposal) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientGoalProposal]) -> [LenientGoalProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientGoalProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientGoalProposals(_ store: any LenientGoalProposalStore, query: LenientGoalProposalQuery) -> [LenientGoalProposal] {
        return query.apply(store.list())
    }
}
