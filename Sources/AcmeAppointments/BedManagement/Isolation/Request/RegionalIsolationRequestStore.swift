import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional isolation requests by code.
    protocol RegionalIsolationRequestStore {
        func find(_ code: String) -> RegionalIsolationRequest?
        func save(_ item: RegionalIsolationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalIsolationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalIsolationRequestStore: RegionalIsolationRequestStore {
        var items: [String: RegionalIsolationRequest]
        var order: [String]

        init(items: [String: RegionalIsolationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalIsolationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalIsolationRequest) {
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

        func list() -> [RegionalIsolationRequest] {
            var out: [RegionalIsolationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalIsolationRequestStore() -> any RegionalIsolationRequestStore {
        return MemoryRegionalIsolationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalIsolationRequestStore: RegionalIsolationRequestStore {
        var inner: MemoryRegionalIsolationRequestStore
        var cache: TTLCache<RegionalIsolationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalIsolationRequestStore, cache: TTLCache<RegionalIsolationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalIsolationRequest? {
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

        func save(_ item: RegionalIsolationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalIsolationRequest] {
            return inner.list()
        }
    }

    static func newCachedRegionalIsolationRequestStore(_ inner: MemoryRegionalIsolationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalIsolationRequestStore {
        return CachedRegionalIsolationRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional isolation requests. Empty fields match all.
    final class RegionalIsolationRequestQuery {
        var unit: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRate: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalIsolationRequest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RegionalIsolationRequest]) -> [RegionalIsolationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalIsolationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalIsolationRequests(_ store: any RegionalIsolationRequestStore, query: RegionalIsolationRequestQuery) -> [RegionalIsolationRequest] {
        return query.apply(store.list())
    }
}
