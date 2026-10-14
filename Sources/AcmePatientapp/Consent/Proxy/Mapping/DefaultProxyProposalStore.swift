import AcmePlatform
import Foundation

extension Consent {
    /// Keeps default proxy proposals by code.
    protocol DefaultProxyProposalStore {
        func find(_ code: String) -> DefaultProxyProposal?
        func save(_ item: DefaultProxyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProxyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProxyProposalStore: DefaultProxyProposalStore {
        var items: [String: DefaultProxyProposal]
        var order: [String]

        init(items: [String: DefaultProxyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProxyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProxyProposal) {
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

        func list() -> [DefaultProxyProposal] {
            var out: [DefaultProxyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProxyProposalStore() -> any DefaultProxyProposalStore {
        return MemoryDefaultProxyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProxyProposalStore: DefaultProxyProposalStore {
        var inner: MemoryDefaultProxyProposalStore
        var cache: TTLCache<DefaultProxyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProxyProposalStore, cache: TTLCache<DefaultProxyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProxyProposal? {
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

        func save(_ item: DefaultProxyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProxyProposal] {
            return inner.list()
        }
    }

    static func newCachedDefaultProxyProposalStore(_ inner: MemoryDefaultProxyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProxyProposalStore {
        return CachedDefaultProxyProposalStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default proxy proposals. Empty fields match all.
    final class DefaultProxyProposalQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProxyProposal) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultProxyProposal]) -> [DefaultProxyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProxyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProxyProposals(_ store: any DefaultProxyProposalStore, query: DefaultProxyProposalQuery) -> [DefaultProxyProposal] {
        return query.apply(store.list())
    }
}
