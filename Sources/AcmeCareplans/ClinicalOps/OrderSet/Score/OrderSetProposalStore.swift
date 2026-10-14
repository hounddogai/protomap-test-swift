import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set proposals by code.
    protocol OrderSetProposalStore {
        func find(_ code: String) -> OrderSetProposal?
        func save(_ item: OrderSetProposal)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetProposalStore: OrderSetProposalStore {
        var items: [String: OrderSetProposal]
        var order: [String]

        init(items: [String: OrderSetProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetProposal) {
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

        func list() -> [OrderSetProposal] {
            var out: [OrderSetProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetProposalStore() -> any OrderSetProposalStore {
        return MemoryOrderSetProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetProposalStore: OrderSetProposalStore {
        var inner: MemoryOrderSetProposalStore
        var cache: TTLCache<OrderSetProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetProposalStore, cache: TTLCache<OrderSetProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetProposal? {
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

        func save(_ item: OrderSetProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetProposal] {
            return inner.list()
        }
    }

    static func newCachedOrderSetProposalStore(_ inner: MemoryOrderSetProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetProposalStore {
        return CachedOrderSetProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set proposals. Empty fields match all.
    final class OrderSetProposalQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetProposal) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [OrderSetProposal]) -> [OrderSetProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetProposals(_ store: any OrderSetProposalStore, query: OrderSetProposalQuery) -> [OrderSetProposal] {
        return query.apply(store.list())
    }
}
