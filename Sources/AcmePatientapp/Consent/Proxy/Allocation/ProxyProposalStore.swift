import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy proposals by code.
    protocol ProxyProposalStore {
        func find(_ code: String) -> ProxyProposal?
        func save(_ item: ProxyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyProposalStore: ProxyProposalStore {
        var items: [String: ProxyProposal]
        var order: [String]

        init(items: [String: ProxyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyProposal) {
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

        func list() -> [ProxyProposal] {
            var out: [ProxyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyProposalStore() -> any ProxyProposalStore {
        return MemoryProxyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyProposalStore: ProxyProposalStore {
        var inner: MemoryProxyProposalStore
        var cache: TTLCache<ProxyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyProposalStore, cache: TTLCache<ProxyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyProposal? {
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

        func save(_ item: ProxyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyProposal] {
            return inner.list()
        }
    }

    static func newCachedProxyProposalStore(_ inner: MemoryProxyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyProposalStore {
        return CachedProxyProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy proposals. Empty fields match all.
    final class ProxyProposalQuery {
        var facility: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyProposal) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyProposal]) -> [ProxyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyProposals(_ store: any ProxyProposalStore, query: ProxyProposalQuery) -> [ProxyProposal] {
        return query.apply(store.list())
    }
}
