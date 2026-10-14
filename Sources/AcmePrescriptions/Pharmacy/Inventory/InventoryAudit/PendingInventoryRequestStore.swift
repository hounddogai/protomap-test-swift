import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending inventory requests by code.
    protocol PendingInventoryRequestStore {
        func find(_ code: String) -> PendingInventoryRequest?
        func save(_ item: PendingInventoryRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingInventoryRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingInventoryRequestStore: PendingInventoryRequestStore {
        var items: [String: PendingInventoryRequest]
        var order: [String]

        init(items: [String: PendingInventoryRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingInventoryRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingInventoryRequest) {
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

        func list() -> [PendingInventoryRequest] {
            var out: [PendingInventoryRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingInventoryRequestStore() -> any PendingInventoryRequestStore {
        return MemoryPendingInventoryRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingInventoryRequestStore: PendingInventoryRequestStore {
        var inner: MemoryPendingInventoryRequestStore
        var cache: TTLCache<PendingInventoryRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingInventoryRequestStore, cache: TTLCache<PendingInventoryRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingInventoryRequest? {
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

        func save(_ item: PendingInventoryRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingInventoryRequest] {
            return inner.list()
        }
    }

    static func newCachedPendingInventoryRequestStore(_ inner: MemoryPendingInventoryRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingInventoryRequestStore {
        return CachedPendingInventoryRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending inventory requests. Empty fields match all.
    final class PendingInventoryRequestQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingInventoryRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingInventoryRequest]) -> [PendingInventoryRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingInventoryRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingInventoryRequests(_ store: any PendingInventoryRequestStore, query: PendingInventoryRequestQuery) -> [PendingInventoryRequest] {
        return query.apply(store.list())
    }
}
