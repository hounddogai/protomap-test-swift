import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority requests by code.
    protocol PriorityRequestStore {
        func find(_ code: String) -> PriorityRequest?
        func save(_ item: PriorityRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityRequestStore: PriorityRequestStore {
        var items: [String: PriorityRequest]
        var order: [String]

        init(items: [String: PriorityRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityRequest) {
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

        func list() -> [PriorityRequest] {
            var out: [PriorityRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityRequestStore() -> any PriorityRequestStore {
        return MemoryPriorityRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityRequestStore: PriorityRequestStore {
        var inner: MemoryPriorityRequestStore
        var cache: TTLCache<PriorityRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityRequestStore, cache: TTLCache<PriorityRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityRequest? {
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

        func save(_ item: PriorityRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityRequest] {
            return inner.list()
        }
    }

    static func newCachedPriorityRequestStore(_ inner: MemoryPriorityRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityRequestStore {
        return CachedPriorityRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority requests. Empty fields match all.
    final class PriorityRequestQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityRequest]) -> [PriorityRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityRequests(_ store: any PriorityRequestStore, query: PriorityRequestQuery) -> [PriorityRequest] {
        return query.apply(store.list())
    }
}
