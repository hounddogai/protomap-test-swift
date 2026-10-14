import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict dispense requests by code.
    protocol StrictDispenseRequestStore {
        func find(_ code: String) -> StrictDispenseRequest?
        func save(_ item: StrictDispenseRequest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDispenseRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDispenseRequestStore: StrictDispenseRequestStore {
        var items: [String: StrictDispenseRequest]
        var order: [String]

        init(items: [String: StrictDispenseRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDispenseRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDispenseRequest) {
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

        func list() -> [StrictDispenseRequest] {
            var out: [StrictDispenseRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDispenseRequestStore() -> any StrictDispenseRequestStore {
        return MemoryStrictDispenseRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDispenseRequestStore: StrictDispenseRequestStore {
        var inner: MemoryStrictDispenseRequestStore
        var cache: TTLCache<StrictDispenseRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDispenseRequestStore, cache: TTLCache<StrictDispenseRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDispenseRequest? {
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

        func save(_ item: StrictDispenseRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDispenseRequest] {
            return inner.list()
        }
    }

    static func newCachedStrictDispenseRequestStore(_ inner: MemoryStrictDispenseRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDispenseRequestStore {
        return CachedStrictDispenseRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict dispense requests. Empty fields match all.
    final class StrictDispenseRequestQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDispenseRequest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictDispenseRequest]) -> [StrictDispenseRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDispenseRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDispenseRequests(_ store: any StrictDispenseRequestStore, query: StrictDispenseRequestQuery) -> [StrictDispenseRequest] {
        return query.apply(store.list())
    }
}
