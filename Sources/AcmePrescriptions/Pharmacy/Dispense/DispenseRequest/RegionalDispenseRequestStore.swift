import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional dispense requests by code.
    protocol RegionalDispenseRequestStore {
        func find(_ code: String) -> RegionalDispenseRequest?
        func save(_ item: RegionalDispenseRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDispenseRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDispenseRequestStore: RegionalDispenseRequestStore {
        var items: [String: RegionalDispenseRequest]
        var order: [String]

        init(items: [String: RegionalDispenseRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDispenseRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDispenseRequest) {
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

        func list() -> [RegionalDispenseRequest] {
            var out: [RegionalDispenseRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDispenseRequestStore() -> any RegionalDispenseRequestStore {
        return MemoryRegionalDispenseRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDispenseRequestStore: RegionalDispenseRequestStore {
        var inner: MemoryRegionalDispenseRequestStore
        var cache: TTLCache<RegionalDispenseRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDispenseRequestStore, cache: TTLCache<RegionalDispenseRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDispenseRequest? {
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

        func save(_ item: RegionalDispenseRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDispenseRequest] {
            return inner.list()
        }
    }

    static func newCachedRegionalDispenseRequestStore(_ inner: MemoryRegionalDispenseRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDispenseRequestStore {
        return CachedRegionalDispenseRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional dispense requests. Empty fields match all.
    final class RegionalDispenseRequestQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDispenseRequest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDispenseRequest]) -> [RegionalDispenseRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDispenseRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDispenseRequests(_ store: any RegionalDispenseRequestStore, query: RegionalDispenseRequestQuery) -> [RegionalDispenseRequest] {
        return query.apply(store.list())
    }
}
