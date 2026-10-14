import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped proxy proposals by code.
    protocol CappedProxyProposalStore {
        func find(_ code: String) -> CappedProxyProposal?
        func save(_ item: CappedProxyProposal)
        func remove(_ code: String) -> Bool
        func list() -> [CappedProxyProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedProxyProposalStore: CappedProxyProposalStore {
        var items: [String: CappedProxyProposal]
        var order: [String]

        init(items: [String: CappedProxyProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedProxyProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedProxyProposal) {
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

        func list() -> [CappedProxyProposal] {
            var out: [CappedProxyProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedProxyProposalStore() -> any CappedProxyProposalStore {
        return MemoryCappedProxyProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedProxyProposalStore: CappedProxyProposalStore {
        var inner: MemoryCappedProxyProposalStore
        var cache: TTLCache<CappedProxyProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedProxyProposalStore, cache: TTLCache<CappedProxyProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedProxyProposal? {
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

        func save(_ item: CappedProxyProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedProxyProposal] {
            return inner.list()
        }
    }

    static func newCachedCappedProxyProposalStore(_ inner: MemoryCappedProxyProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedProxyProposalStore {
        return CachedCappedProxyProposalStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped proxy proposals. Empty fields match all.
    final class CappedProxyProposalQuery {
        var channel: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedProxyProposal) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedProxyProposal]) -> [CappedProxyProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedProxyProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedProxyProposals(_ store: any CappedProxyProposalStore, query: CappedProxyProposalQuery) -> [CappedProxyProposal] {
        return query.apply(store.list())
    }
}
