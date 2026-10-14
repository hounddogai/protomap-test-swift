import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted transfer agreements by code.
    protocol WeightedTransferAgreementStore {
        func find(_ code: String) -> WeightedTransferAgreement?
        func save(_ item: WeightedTransferAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTransferAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTransferAgreementStore: WeightedTransferAgreementStore {
        var items: [String: WeightedTransferAgreement]
        var order: [String]

        init(items: [String: WeightedTransferAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTransferAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTransferAgreement) {
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

        func list() -> [WeightedTransferAgreement] {
            var out: [WeightedTransferAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTransferAgreementStore() -> any WeightedTransferAgreementStore {
        return MemoryWeightedTransferAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTransferAgreementStore: WeightedTransferAgreementStore {
        var inner: MemoryWeightedTransferAgreementStore
        var cache: TTLCache<WeightedTransferAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTransferAgreementStore, cache: TTLCache<WeightedTransferAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTransferAgreement? {
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

        func save(_ item: WeightedTransferAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTransferAgreement] {
            return inner.list()
        }
    }

    static func newCachedWeightedTransferAgreementStore(_ inner: MemoryWeightedTransferAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTransferAgreementStore {
        return CachedWeightedTransferAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted transfer agreements. Empty fields match all.
    final class WeightedTransferAgreementQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTransferAgreement) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [WeightedTransferAgreement]) -> [WeightedTransferAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTransferAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTransferAgreements(_ store: any WeightedTransferAgreementStore, query: WeightedTransferAgreementQuery) -> [WeightedTransferAgreement] {
        return query.apply(store.list())
    }
}
