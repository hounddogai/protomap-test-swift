import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted result requests by code.
    protocol WeightedResultRequestStore {
        func find(_ code: String) -> WeightedResultRequest?
        func save(_ item: WeightedResultRequest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedResultRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedResultRequestStore: WeightedResultRequestStore {
        var items: [String: WeightedResultRequest]
        var order: [String]

        init(items: [String: WeightedResultRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedResultRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedResultRequest) {
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

        func list() -> [WeightedResultRequest] {
            var out: [WeightedResultRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedResultRequestStore() -> any WeightedResultRequestStore {
        return MemoryWeightedResultRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedResultRequestStore: WeightedResultRequestStore {
        var inner: MemoryWeightedResultRequestStore
        var cache: TTLCache<WeightedResultRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedResultRequestStore, cache: TTLCache<WeightedResultRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedResultRequest? {
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

        func save(_ item: WeightedResultRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedResultRequest] {
            return inner.list()
        }
    }

    static func newCachedWeightedResultRequestStore(_ inner: MemoryWeightedResultRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedResultRequestStore {
        return CachedWeightedResultRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted result requests. Empty fields match all.
    final class WeightedResultRequestQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedResultRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedResultRequest]) -> [WeightedResultRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedResultRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedResultRequests(_ store: any WeightedResultRequestStore, query: WeightedResultRequestQuery) -> [WeightedResultRequest] {
        return query.apply(store.list())
    }
}
