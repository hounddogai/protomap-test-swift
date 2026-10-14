import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps weighted transfer requests by code.
    protocol WeightedTransferRequestStore {
        func find(_ code: String) -> WeightedTransferRequest?
        func save(_ item: WeightedTransferRequest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedTransferRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedTransferRequestStore: WeightedTransferRequestStore {
        var items: [String: WeightedTransferRequest]
        var order: [String]

        init(items: [String: WeightedTransferRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedTransferRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedTransferRequest) {
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

        func list() -> [WeightedTransferRequest] {
            var out: [WeightedTransferRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedTransferRequestStore() -> any WeightedTransferRequestStore {
        return MemoryWeightedTransferRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedTransferRequestStore: WeightedTransferRequestStore {
        var inner: MemoryWeightedTransferRequestStore
        var cache: TTLCache<WeightedTransferRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedTransferRequestStore, cache: TTLCache<WeightedTransferRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedTransferRequest? {
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

        func save(_ item: WeightedTransferRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedTransferRequest] {
            return inner.list()
        }
    }

    static func newCachedWeightedTransferRequestStore(_ inner: MemoryWeightedTransferRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedTransferRequestStore {
        return CachedWeightedTransferRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted transfer requests. Empty fields match all.
    final class WeightedTransferRequestQuery {
        var locale: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedTransferRequest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedTransferRequest]) -> [WeightedTransferRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedTransferRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedTransferRequests(_ store: any WeightedTransferRequestStore, query: WeightedTransferRequestQuery) -> [WeightedTransferRequest] {
        return query.apply(store.list())
    }
}
