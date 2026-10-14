import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional inventory requests by code.
    protocol RegionalInventoryRequestStore {
        func find(_ code: String) -> RegionalInventoryRequest?
        func save(_ item: RegionalInventoryRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalInventoryRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalInventoryRequestStore: RegionalInventoryRequestStore {
        var items: [String: RegionalInventoryRequest]
        var order: [String]

        init(items: [String: RegionalInventoryRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalInventoryRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalInventoryRequest) {
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

        func list() -> [RegionalInventoryRequest] {
            var out: [RegionalInventoryRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalInventoryRequestStore() -> any RegionalInventoryRequestStore {
        return MemoryRegionalInventoryRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalInventoryRequestStore: RegionalInventoryRequestStore {
        var inner: MemoryRegionalInventoryRequestStore
        var cache: TTLCache<RegionalInventoryRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalInventoryRequestStore, cache: TTLCache<RegionalInventoryRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalInventoryRequest? {
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

        func save(_ item: RegionalInventoryRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalInventoryRequest] {
            return inner.list()
        }
    }

    static func newCachedRegionalInventoryRequestStore(_ inner: MemoryRegionalInventoryRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalInventoryRequestStore {
        return CachedRegionalInventoryRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional inventory requests. Empty fields match all.
    final class RegionalInventoryRequestQuery {
        var segment: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalInventoryRequest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalInventoryRequest]) -> [RegionalInventoryRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalInventoryRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalInventoryRequests(_ store: any RegionalInventoryRequestStore, query: RegionalInventoryRequestQuery) -> [RegionalInventoryRequest] {
        return query.apply(store.list())
    }
}
