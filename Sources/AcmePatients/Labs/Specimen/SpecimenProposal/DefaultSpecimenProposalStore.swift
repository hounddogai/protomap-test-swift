import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default specimen proposals by code.
    protocol DefaultSpecimenProposalStore {
        func find(_ code: String) -> DefaultSpecimenProposal?
        func save(_ item: DefaultSpecimenProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSpecimenProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSpecimenProposalStore: DefaultSpecimenProposalStore {
        var items: [String: DefaultSpecimenProposal]
        var order: [String]

        init(items: [String: DefaultSpecimenProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSpecimenProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSpecimenProposal) {
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

        func list() -> [DefaultSpecimenProposal] {
            var out: [DefaultSpecimenProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSpecimenProposalStore() -> any DefaultSpecimenProposalStore {
        return MemoryDefaultSpecimenProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSpecimenProposalStore: DefaultSpecimenProposalStore {
        var inner: MemoryDefaultSpecimenProposalStore
        var cache: TTLCache<DefaultSpecimenProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSpecimenProposalStore, cache: TTLCache<DefaultSpecimenProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSpecimenProposal? {
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

        func save(_ item: DefaultSpecimenProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSpecimenProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultSpecimenProposalStore(_ inner: MemoryDefaultSpecimenProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSpecimenProposalStore {
        return CachedDefaultSpecimenProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default specimen proposals. Empty fields match all.
    final class DefaultSpecimenProposalQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSpecimenProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultSpecimenProposal]) -> [DefaultSpecimenProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSpecimenProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSpecimenProposals(_ store: any DefaultSpecimenProposalStore, query: DefaultSpecimenProposalQuery) -> [DefaultSpecimenProposal] {
        return query.apply(store.list())
    }
}
