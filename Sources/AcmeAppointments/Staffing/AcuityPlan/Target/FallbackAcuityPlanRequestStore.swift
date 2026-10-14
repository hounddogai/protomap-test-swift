import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback acuity plan requests by code.
    protocol FallbackAcuityPlanRequestStore {
        func find(_ code: String) -> FallbackAcuityPlanRequest?
        func save(_ item: FallbackAcuityPlanRequest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAcuityPlanRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAcuityPlanRequestStore: FallbackAcuityPlanRequestStore {
        var items: [String: FallbackAcuityPlanRequest]
        var order: [String]

        init(items: [String: FallbackAcuityPlanRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAcuityPlanRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAcuityPlanRequest) {
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

        func list() -> [FallbackAcuityPlanRequest] {
            var out: [FallbackAcuityPlanRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAcuityPlanRequestStore() -> any FallbackAcuityPlanRequestStore {
        return MemoryFallbackAcuityPlanRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAcuityPlanRequestStore: FallbackAcuityPlanRequestStore {
        var inner: MemoryFallbackAcuityPlanRequestStore
        var cache: TTLCache<FallbackAcuityPlanRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAcuityPlanRequestStore, cache: TTLCache<FallbackAcuityPlanRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAcuityPlanRequest? {
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

        func save(_ item: FallbackAcuityPlanRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAcuityPlanRequest] {
            return inner.list()
        }
    }

    static func newCachedFallbackAcuityPlanRequestStore(_ inner: MemoryFallbackAcuityPlanRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAcuityPlanRequestStore {
        return CachedFallbackAcuityPlanRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback acuity plan requests. Empty fields match all.
    final class FallbackAcuityPlanRequestQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAcuityPlanRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAcuityPlanRequest]) -> [FallbackAcuityPlanRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAcuityPlanRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAcuityPlanRequests(_ store: any FallbackAcuityPlanRequestStore, query: FallbackAcuityPlanRequestQuery) -> [FallbackAcuityPlanRequest] {
        return query.apply(store.list())
    }
}
