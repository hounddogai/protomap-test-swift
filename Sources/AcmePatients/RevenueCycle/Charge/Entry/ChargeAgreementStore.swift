import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge agreements by code.
    protocol ChargeAgreementStore {
        func find(_ code: String) -> ChargeAgreement?
        func save(_ item: ChargeAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeAgreementStore: ChargeAgreementStore {
        var items: [String: ChargeAgreement]
        var order: [String]

        init(items: [String: ChargeAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeAgreement) {
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

        func list() -> [ChargeAgreement] {
            var out: [ChargeAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeAgreementStore() -> any ChargeAgreementStore {
        return MemoryChargeAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeAgreementStore: ChargeAgreementStore {
        var inner: MemoryChargeAgreementStore
        var cache: TTLCache<ChargeAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeAgreementStore, cache: TTLCache<ChargeAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeAgreement? {
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

        func save(_ item: ChargeAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeAgreement] {
            return inner.list()
        }
    }

    static func newCachedChargeAgreementStore(_ inner: MemoryChargeAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeAgreementStore {
        return CachedChargeAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge agreements. Empty fields match all.
    final class ChargeAgreementQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeAgreement) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeAgreement]) -> [ChargeAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeAgreements(_ store: any ChargeAgreementStore, query: ChargeAgreementQuery) -> [ChargeAgreement] {
        return query.apply(store.list())
    }
}
