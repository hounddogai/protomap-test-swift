import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive care protocol proposals by code.
    protocol AdaptiveCareProtocolProposalStore {
        func find(_ code: String) -> AdaptiveCareProtocolProposal?
        func save(_ item: AdaptiveCareProtocolProposal)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCareProtocolProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCareProtocolProposalStore: AdaptiveCareProtocolProposalStore {
        var items: [String: AdaptiveCareProtocolProposal]
        var order: [String]

        init(items: [String: AdaptiveCareProtocolProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCareProtocolProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCareProtocolProposal) {
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

        func list() -> [AdaptiveCareProtocolProposal] {
            var out: [AdaptiveCareProtocolProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCareProtocolProposalStore() -> any AdaptiveCareProtocolProposalStore {
        return MemoryAdaptiveCareProtocolProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCareProtocolProposalStore: AdaptiveCareProtocolProposalStore {
        var inner: MemoryAdaptiveCareProtocolProposalStore
        var cache: TTLCache<AdaptiveCareProtocolProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCareProtocolProposalStore, cache: TTLCache<AdaptiveCareProtocolProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCareProtocolProposal? {
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

        func save(_ item: AdaptiveCareProtocolProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCareProtocolProposal] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCareProtocolProposalStore(_ inner: MemoryAdaptiveCareProtocolProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCareProtocolProposalStore {
        return CachedAdaptiveCareProtocolProposalStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive care protocol proposals. Empty fields match all.
    final class AdaptiveCareProtocolProposalQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCareProtocolProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCareProtocolProposal]) -> [AdaptiveCareProtocolProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCareProtocolProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCareProtocolProposals(_ store: any AdaptiveCareProtocolProposalStore, query: AdaptiveCareProtocolProposalQuery) -> [AdaptiveCareProtocolProposal] {
        return query.apply(store.list())
    }
}
