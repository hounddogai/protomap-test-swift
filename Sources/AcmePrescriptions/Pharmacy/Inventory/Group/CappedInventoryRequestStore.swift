import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped inventory requests by code.
    protocol CappedInventoryRequestStore {
        func find(_ code: String) -> CappedInventoryRequest?
        func save(_ item: CappedInventoryRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CappedInventoryRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedInventoryRequestStore: CappedInventoryRequestStore {
        var items: [String: CappedInventoryRequest]
        var order: [String]

        init(items: [String: CappedInventoryRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedInventoryRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedInventoryRequest) {
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

        func list() -> [CappedInventoryRequest] {
            var out: [CappedInventoryRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedInventoryRequestStore() -> any CappedInventoryRequestStore {
        return MemoryCappedInventoryRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedInventoryRequestStore: CappedInventoryRequestStore {
        var inner: MemoryCappedInventoryRequestStore
        var cache: TTLCache<CappedInventoryRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedInventoryRequestStore, cache: TTLCache<CappedInventoryRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedInventoryRequest? {
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

        func save(_ item: CappedInventoryRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedInventoryRequest] {
            return inner.list()
        }
    }

    static func newCachedCappedInventoryRequestStore(_ inner: MemoryCappedInventoryRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedInventoryRequestStore {
        return CachedCappedInventoryRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped inventory requests. Empty fields match all.
    final class CappedInventoryRequestQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedInventoryRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedInventoryRequest]) -> [CappedInventoryRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedInventoryRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedInventoryRequests(_ store: any CappedInventoryRequestStore, query: CappedInventoryRequestQuery) -> [CappedInventoryRequest] {
        return query.apply(store.list())
    }
}
