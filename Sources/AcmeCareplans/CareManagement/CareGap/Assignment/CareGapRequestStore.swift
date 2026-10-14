import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap requests by code.
    protocol CareGapRequestStore {
        func find(_ code: String) -> CareGapRequest?
        func save(_ item: CareGapRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapRequestStore: CareGapRequestStore {
        var items: [String: CareGapRequest]
        var order: [String]

        init(items: [String: CareGapRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapRequest) {
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

        func list() -> [CareGapRequest] {
            var out: [CareGapRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapRequestStore() -> any CareGapRequestStore {
        return MemoryCareGapRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapRequestStore: CareGapRequestStore {
        var inner: MemoryCareGapRequestStore
        var cache: TTLCache<CareGapRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapRequestStore, cache: TTLCache<CareGapRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapRequest? {
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

        func save(_ item: CareGapRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapRequest] {
            return inner.list()
        }
    }

    static func newCachedCareGapRequestStore(_ inner: MemoryCareGapRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapRequestStore {
        return CachedCareGapRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap requests. Empty fields match all.
    final class CareGapRequestQuery {
        var facility: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minScore: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapRequest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapRequest]) -> [CareGapRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapRequests(_ store: any CareGapRequestStore, query: CareGapRequestQuery) -> [CareGapRequest] {
        return query.apply(store.list())
    }
}
