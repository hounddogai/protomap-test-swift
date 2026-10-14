import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default care protocol proposals by code.
    protocol DefaultCareProtocolProposalStore {
        func find(_ code: String) -> DefaultCareProtocolProposal?
        func save(_ item: DefaultCareProtocolProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolProposalStore: DefaultCareProtocolProposalStore {
        var items: [String: DefaultCareProtocolProposal]
        var order: [String]

        init(items: [String: DefaultCareProtocolProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolProposal) {
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

        func list() -> [DefaultCareProtocolProposal] {
            var out: [DefaultCareProtocolProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolProposalStore() -> any DefaultCareProtocolProposalStore {
        return MemoryDefaultCareProtocolProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolProposalStore: DefaultCareProtocolProposalStore {
        var inner: MemoryDefaultCareProtocolProposalStore
        var cache: TTLCache<DefaultCareProtocolProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolProposalStore, cache: TTLCache<DefaultCareProtocolProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolProposal? {
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

        func save(_ item: DefaultCareProtocolProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolProposalStore(_ inner: MemoryDefaultCareProtocolProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolProposalStore {
        return CachedDefaultCareProtocolProposalStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol proposals. Empty fields match all.
    final class DefaultCareProtocolProposalQuery {
        var region: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRetries: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolProposal) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [DefaultCareProtocolProposal]) -> [DefaultCareProtocolProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolProposals(_ store: any DefaultCareProtocolProposalStore, query: DefaultCareProtocolProposalQuery) -> [DefaultCareProtocolProposal] {
        return query.apply(store.list())
    }
}
