import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback dispense requests by code.
    protocol FallbackDispenseRequestStore {
        func find(_ code: String) -> FallbackDispenseRequest?
        func save(_ item: FallbackDispenseRequest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDispenseRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDispenseRequestStore: FallbackDispenseRequestStore {
        var items: [String: FallbackDispenseRequest]
        var order: [String]

        init(items: [String: FallbackDispenseRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDispenseRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDispenseRequest) {
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

        func list() -> [FallbackDispenseRequest] {
            var out: [FallbackDispenseRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDispenseRequestStore() -> any FallbackDispenseRequestStore {
        return MemoryFallbackDispenseRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDispenseRequestStore: FallbackDispenseRequestStore {
        var inner: MemoryFallbackDispenseRequestStore
        var cache: TTLCache<FallbackDispenseRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDispenseRequestStore, cache: TTLCache<FallbackDispenseRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDispenseRequest? {
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

        func save(_ item: FallbackDispenseRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDispenseRequest] {
            return inner.list()
        }
    }

    static func newCachedFallbackDispenseRequestStore(_ inner: MemoryFallbackDispenseRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDispenseRequestStore {
        return CachedFallbackDispenseRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback dispense requests. Empty fields match all.
    final class FallbackDispenseRequestQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDispenseRequest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [FallbackDispenseRequest]) -> [FallbackDispenseRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDispenseRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDispenseRequests(_ store: any FallbackDispenseRequestStore, query: FallbackDispenseRequestQuery) -> [FallbackDispenseRequest] {
        return query.apply(store.list())
    }
}
