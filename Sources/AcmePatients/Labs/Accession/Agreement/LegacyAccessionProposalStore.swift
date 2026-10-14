import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy accession proposals by code.
    protocol LegacyAccessionProposalStore {
        func find(_ code: String) -> LegacyAccessionProposal?
        func save(_ item: LegacyAccessionProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAccessionProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAccessionProposalStore: LegacyAccessionProposalStore {
        var items: [String: LegacyAccessionProposal]
        var order: [String]

        init(items: [String: LegacyAccessionProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAccessionProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAccessionProposal) {
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

        func list() -> [LegacyAccessionProposal] {
            var out: [LegacyAccessionProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAccessionProposalStore() -> any LegacyAccessionProposalStore {
        return MemoryLegacyAccessionProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAccessionProposalStore: LegacyAccessionProposalStore {
        var inner: MemoryLegacyAccessionProposalStore
        var cache: TTLCache<LegacyAccessionProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAccessionProposalStore, cache: TTLCache<LegacyAccessionProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAccessionProposal? {
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

        func save(_ item: LegacyAccessionProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAccessionProposal] {
            return inner.list()
        }
    }

    static func newCachedLegacyAccessionProposalStore(_ inner: MemoryLegacyAccessionProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAccessionProposalStore {
        return CachedLegacyAccessionProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy accession proposals. Empty fields match all.
    final class LegacyAccessionProposalQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAccessionProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LegacyAccessionProposal]) -> [LegacyAccessionProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAccessionProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAccessionProposals(_ store: any LegacyAccessionProposalStore, query: LegacyAccessionProposalQuery) -> [LegacyAccessionProposal] {
        return query.apply(store.list())
    }
}
