import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy goal proposals by code.
    protocol LegacyGoalProposalStore {
        func find(_ code: String) -> LegacyGoalProposal?
        func save(_ item: LegacyGoalProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyGoalProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyGoalProposalStore: LegacyGoalProposalStore {
        var items: [String: LegacyGoalProposal]
        var order: [String]

        init(items: [String: LegacyGoalProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyGoalProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyGoalProposal) {
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

        func list() -> [LegacyGoalProposal] {
            var out: [LegacyGoalProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyGoalProposalStore() -> any LegacyGoalProposalStore {
        return MemoryLegacyGoalProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyGoalProposalStore: LegacyGoalProposalStore {
        var inner: MemoryLegacyGoalProposalStore
        var cache: TTLCache<LegacyGoalProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyGoalProposalStore, cache: TTLCache<LegacyGoalProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyGoalProposal? {
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

        func save(_ item: LegacyGoalProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyGoalProposal] {
            return inner.list()
        }
    }

    static func newCachedLegacyGoalProposalStore(_ inner: MemoryLegacyGoalProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyGoalProposalStore {
        return CachedLegacyGoalProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy goal proposals. Empty fields match all.
    final class LegacyGoalProposalQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyGoalProposal) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyGoalProposal]) -> [LegacyGoalProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyGoalProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyGoalProposals(_ store: any LegacyGoalProposalStore, query: LegacyGoalProposalQuery) -> [LegacyGoalProposal] {
        return query.apply(store.list())
    }
}
