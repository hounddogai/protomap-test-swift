import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary acuity plan requests by code.
    protocol PrimaryAcuityPlanRequestStore {
        func find(_ code: String) -> PrimaryAcuityPlanRequest?
        func save(_ item: PrimaryAcuityPlanRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAcuityPlanRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAcuityPlanRequestStore: PrimaryAcuityPlanRequestStore {
        var items: [String: PrimaryAcuityPlanRequest]
        var order: [String]

        init(items: [String: PrimaryAcuityPlanRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAcuityPlanRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAcuityPlanRequest) {
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

        func list() -> [PrimaryAcuityPlanRequest] {
            var out: [PrimaryAcuityPlanRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAcuityPlanRequestStore() -> any PrimaryAcuityPlanRequestStore {
        return MemoryPrimaryAcuityPlanRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAcuityPlanRequestStore: PrimaryAcuityPlanRequestStore {
        var inner: MemoryPrimaryAcuityPlanRequestStore
        var cache: TTLCache<PrimaryAcuityPlanRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAcuityPlanRequestStore, cache: TTLCache<PrimaryAcuityPlanRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAcuityPlanRequest? {
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

        func save(_ item: PrimaryAcuityPlanRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAcuityPlanRequest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAcuityPlanRequestStore(_ inner: MemoryPrimaryAcuityPlanRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAcuityPlanRequestStore {
        return CachedPrimaryAcuityPlanRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary acuity plan requests. Empty fields match all.
    final class PrimaryAcuityPlanRequestQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAcuityPlanRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAcuityPlanRequest]) -> [PrimaryAcuityPlanRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAcuityPlanRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAcuityPlanRequests(_ store: any PrimaryAcuityPlanRequestStore, query: PrimaryAcuityPlanRequestQuery) -> [PrimaryAcuityPlanRequest] {
        return query.apply(store.list())
    }
}
