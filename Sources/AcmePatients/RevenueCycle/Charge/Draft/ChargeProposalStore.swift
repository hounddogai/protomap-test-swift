import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge proposals by code.
    protocol ChargeProposalStore {
        func find(_ code: String) -> ChargeProposal?
        func save(_ item: ChargeProposal)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeProposalStore: ChargeProposalStore {
        var items: [String: ChargeProposal]
        var order: [String]

        init(items: [String: ChargeProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeProposal) {
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

        func list() -> [ChargeProposal] {
            var out: [ChargeProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeProposalStore() -> any ChargeProposalStore {
        return MemoryChargeProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeProposalStore: ChargeProposalStore {
        var inner: MemoryChargeProposalStore
        var cache: TTLCache<ChargeProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeProposalStore, cache: TTLCache<ChargeProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeProposal? {
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

        func save(_ item: ChargeProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeProposal] {
            return inner.list()
        }
    }

    static func newCachedChargeProposalStore(_ inner: MemoryChargeProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeProposalStore {
        return CachedChargeProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge proposals. Empty fields match all.
    final class ChargeProposalQuery {
        var segment: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRate: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeProposal) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeProposal]) -> [ChargeProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeProposals(_ store: any ChargeProposalStore, query: ChargeProposalQuery) -> [ChargeProposal] {
        return query.apply(store.list())
    }
}
