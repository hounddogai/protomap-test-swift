import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default task proposals by code.
    protocol DefaultTaskProposalStore {
        func find(_ code: String) -> DefaultTaskProposal?
        func save(_ item: DefaultTaskProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultTaskProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultTaskProposalStore: DefaultTaskProposalStore {
        var items: [String: DefaultTaskProposal]
        var order: [String]

        init(items: [String: DefaultTaskProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultTaskProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultTaskProposal) {
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

        func list() -> [DefaultTaskProposal] {
            var out: [DefaultTaskProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultTaskProposalStore() -> any DefaultTaskProposalStore {
        return MemoryDefaultTaskProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultTaskProposalStore: DefaultTaskProposalStore {
        var inner: MemoryDefaultTaskProposalStore
        var cache: TTLCache<DefaultTaskProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultTaskProposalStore, cache: TTLCache<DefaultTaskProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultTaskProposal? {
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

        func save(_ item: DefaultTaskProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultTaskProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultTaskProposalStore(_ inner: MemoryDefaultTaskProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultTaskProposalStore {
        return CachedDefaultTaskProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default task proposals. Empty fields match all.
    final class DefaultTaskProposalQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultTaskProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultTaskProposal]) -> [DefaultTaskProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultTaskProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultTaskProposals(_ store: any DefaultTaskProposalStore, query: DefaultTaskProposalQuery) -> [DefaultTaskProposal] {
        return query.apply(store.list())
    }
}
