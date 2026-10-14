import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy care protocol proposals by code.
    protocol LegacyCareProtocolProposalStore {
        func find(_ code: String) -> LegacyCareProtocolProposal?
        func save(_ item: LegacyCareProtocolProposal)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCareProtocolProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCareProtocolProposalStore: LegacyCareProtocolProposalStore {
        var items: [String: LegacyCareProtocolProposal]
        var order: [String]

        init(items: [String: LegacyCareProtocolProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCareProtocolProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCareProtocolProposal) {
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

        func list() -> [LegacyCareProtocolProposal] {
            var out: [LegacyCareProtocolProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCareProtocolProposalStore() -> any LegacyCareProtocolProposalStore {
        return MemoryLegacyCareProtocolProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCareProtocolProposalStore: LegacyCareProtocolProposalStore {
        var inner: MemoryLegacyCareProtocolProposalStore
        var cache: TTLCache<LegacyCareProtocolProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCareProtocolProposalStore, cache: TTLCache<LegacyCareProtocolProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCareProtocolProposal? {
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

        func save(_ item: LegacyCareProtocolProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCareProtocolProposal] {
            return inner.list()
        }
    }

    static func newCachedLegacyCareProtocolProposalStore(_ inner: MemoryLegacyCareProtocolProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCareProtocolProposalStore {
        return CachedLegacyCareProtocolProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy care protocol proposals. Empty fields match all.
    final class LegacyCareProtocolProposalQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCareProtocolProposal) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCareProtocolProposal]) -> [LegacyCareProtocolProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCareProtocolProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCareProtocolProposals(_ store: any LegacyCareProtocolProposalStore, query: LegacyCareProtocolProposalQuery) -> [LegacyCareProtocolProposal] {
        return query.apply(store.list())
    }
}
