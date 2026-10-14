import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal rounding requests by code.
    protocol SeasonalRoundingRequestStore {
        func find(_ code: String) -> SeasonalRoundingRequest?
        func save(_ item: SeasonalRoundingRequest)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRoundingRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRoundingRequestStore: SeasonalRoundingRequestStore {
        var items: [String: SeasonalRoundingRequest]
        var order: [String]

        init(items: [String: SeasonalRoundingRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRoundingRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRoundingRequest) {
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

        func list() -> [SeasonalRoundingRequest] {
            var out: [SeasonalRoundingRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRoundingRequestStore() -> any SeasonalRoundingRequestStore {
        return MemorySeasonalRoundingRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRoundingRequestStore: SeasonalRoundingRequestStore {
        var inner: MemorySeasonalRoundingRequestStore
        var cache: TTLCache<SeasonalRoundingRequest>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRoundingRequestStore, cache: TTLCache<SeasonalRoundingRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRoundingRequest? {
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

        func save(_ item: SeasonalRoundingRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRoundingRequest] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRoundingRequestStore(_ inner: MemorySeasonalRoundingRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRoundingRequestStore {
        return CachedSeasonalRoundingRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal rounding requests. Empty fields match all.
    final class SeasonalRoundingRequestQuery {
        var unit: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRoundingRequest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalRoundingRequest]) -> [SeasonalRoundingRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRoundingRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRoundingRequests(_ store: any SeasonalRoundingRequestStore, query: SeasonalRoundingRequestQuery) -> [SeasonalRoundingRequest] {
        return query.apply(store.list())
    }
}
