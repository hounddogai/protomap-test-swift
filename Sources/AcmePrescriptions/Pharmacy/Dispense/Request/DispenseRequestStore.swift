import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense requests by code.
    protocol DispenseRequestStore {
        func find(_ code: String) -> DispenseRequest?
        func save(_ item: DispenseRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseRequestStore: DispenseRequestStore {
        var items: [String: DispenseRequest]
        var order: [String]

        init(items: [String: DispenseRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseRequest) {
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

        func list() -> [DispenseRequest] {
            var out: [DispenseRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseRequestStore() -> any DispenseRequestStore {
        return MemoryDispenseRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseRequestStore: DispenseRequestStore {
        var inner: MemoryDispenseRequestStore
        var cache: TTLCache<DispenseRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseRequestStore, cache: TTLCache<DispenseRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseRequest? {
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

        func save(_ item: DispenseRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseRequest] {
            return inner.list()
        }
    }

    static func newCachedDispenseRequestStore(_ inner: MemoryDispenseRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseRequestStore {
        return CachedDispenseRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense requests. Empty fields match all.
    final class DispenseRequestQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseRequest]) -> [DispenseRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseRequests(_ store: any DispenseRequestStore, query: DispenseRequestQuery) -> [DispenseRequest] {
        return query.apply(store.list())
    }
}
