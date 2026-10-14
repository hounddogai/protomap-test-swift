import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global skill mix proposals by code.
    protocol GlobalSkillMixProposalStore {
        func find(_ code: String) -> GlobalSkillMixProposal?
        func save(_ item: GlobalSkillMixProposal)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSkillMixProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSkillMixProposalStore: GlobalSkillMixProposalStore {
        var items: [String: GlobalSkillMixProposal]
        var order: [String]

        init(items: [String: GlobalSkillMixProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSkillMixProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSkillMixProposal) {
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

        func list() -> [GlobalSkillMixProposal] {
            var out: [GlobalSkillMixProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSkillMixProposalStore() -> any GlobalSkillMixProposalStore {
        return MemoryGlobalSkillMixProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSkillMixProposalStore: GlobalSkillMixProposalStore {
        var inner: MemoryGlobalSkillMixProposalStore
        var cache: TTLCache<GlobalSkillMixProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSkillMixProposalStore, cache: TTLCache<GlobalSkillMixProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSkillMixProposal? {
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

        func save(_ item: GlobalSkillMixProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSkillMixProposal] {
            return inner.list()
        }
    }

    static func newCachedGlobalSkillMixProposalStore(_ inner: MemoryGlobalSkillMixProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSkillMixProposalStore {
        return CachedGlobalSkillMixProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global skill mix proposals. Empty fields match all.
    final class GlobalSkillMixProposalQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSkillMixProposal) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSkillMixProposal]) -> [GlobalSkillMixProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSkillMixProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSkillMixProposals(_ store: any GlobalSkillMixProposalStore, query: GlobalSkillMixProposalQuery) -> [GlobalSkillMixProposal] {
        return query.apply(store.list())
    }
}
