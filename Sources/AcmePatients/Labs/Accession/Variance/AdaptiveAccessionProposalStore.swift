import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive accession proposals by code.
    protocol AdaptiveAccessionProposalStore {
        func find(_ code: String) -> AdaptiveAccessionProposal?
        func save(_ item: AdaptiveAccessionProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveAccessionProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveAccessionProposalStore: AdaptiveAccessionProposalStore {
        var items: [String: AdaptiveAccessionProposal]
        var order: [String]

        init(items: [String: AdaptiveAccessionProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveAccessionProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveAccessionProposal) {
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

        func list() -> [AdaptiveAccessionProposal] {
            var out: [AdaptiveAccessionProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveAccessionProposalStore() -> any AdaptiveAccessionProposalStore {
        return MemoryAdaptiveAccessionProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveAccessionProposalStore: AdaptiveAccessionProposalStore {
        var inner: MemoryAdaptiveAccessionProposalStore
        var cache: TTLCache<AdaptiveAccessionProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveAccessionProposalStore, cache: TTLCache<AdaptiveAccessionProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveAccessionProposal? {
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

        func save(_ item: AdaptiveAccessionProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveAccessionProposal] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveAccessionProposalStore(_ inner: MemoryAdaptiveAccessionProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveAccessionProposalStore {
        return CachedAdaptiveAccessionProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive accession proposals. Empty fields match all.
    final class AdaptiveAccessionProposalQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveAccessionProposal) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [AdaptiveAccessionProposal]) -> [AdaptiveAccessionProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveAccessionProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveAccessionProposals(_ store: any AdaptiveAccessionProposalStore, query: AdaptiveAccessionProposalQuery) -> [AdaptiveAccessionProposal] {
        return query.apply(store.list())
    }
}
