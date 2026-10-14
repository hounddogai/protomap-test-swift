import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set agreements by code.
    protocol OrderSetAgreementStore {
        func find(_ code: String) -> OrderSetAgreement?
        func save(_ item: OrderSetAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetAgreementStore: OrderSetAgreementStore {
        var items: [String: OrderSetAgreement]
        var order: [String]

        init(items: [String: OrderSetAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetAgreement) {
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

        func list() -> [OrderSetAgreement] {
            var out: [OrderSetAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetAgreementStore() -> any OrderSetAgreementStore {
        return MemoryOrderSetAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetAgreementStore: OrderSetAgreementStore {
        var inner: MemoryOrderSetAgreementStore
        var cache: TTLCache<OrderSetAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetAgreementStore, cache: TTLCache<OrderSetAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetAgreement? {
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

        func save(_ item: OrderSetAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetAgreement] {
            return inner.list()
        }
    }

    static func newCachedOrderSetAgreementStore(_ inner: MemoryOrderSetAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetAgreementStore {
        return CachedOrderSetAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set agreements. Empty fields match all.
    final class OrderSetAgreementQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [OrderSetAgreement]) -> [OrderSetAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetAgreements(_ store: any OrderSetAgreementStore, query: OrderSetAgreementQuery) -> [OrderSetAgreement] {
        return query.apply(store.list())
    }
}
