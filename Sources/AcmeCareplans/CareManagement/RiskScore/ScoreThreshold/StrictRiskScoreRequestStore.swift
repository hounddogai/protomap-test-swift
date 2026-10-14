import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict risk score requests by code.
    protocol StrictRiskScoreRequestStore {
        func find(_ code: String) -> StrictRiskScoreRequest?
        func save(_ item: StrictRiskScoreRequest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRiskScoreRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRiskScoreRequestStore: StrictRiskScoreRequestStore {
        var items: [String: StrictRiskScoreRequest]
        var order: [String]

        init(items: [String: StrictRiskScoreRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRiskScoreRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRiskScoreRequest) {
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

        func list() -> [StrictRiskScoreRequest] {
            var out: [StrictRiskScoreRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRiskScoreRequestStore() -> any StrictRiskScoreRequestStore {
        return MemoryStrictRiskScoreRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRiskScoreRequestStore: StrictRiskScoreRequestStore {
        var inner: MemoryStrictRiskScoreRequestStore
        var cache: TTLCache<StrictRiskScoreRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRiskScoreRequestStore, cache: TTLCache<StrictRiskScoreRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRiskScoreRequest? {
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

        func save(_ item: StrictRiskScoreRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRiskScoreRequest] {
            return inner.list()
        }
    }

    static func newCachedStrictRiskScoreRequestStore(_ inner: MemoryStrictRiskScoreRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRiskScoreRequestStore {
        return CachedStrictRiskScoreRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict risk score requests. Empty fields match all.
    final class StrictRiskScoreRequestQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRiskScoreRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRiskScoreRequest]) -> [StrictRiskScoreRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRiskScoreRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRiskScoreRequests(_ store: any StrictRiskScoreRequestStore, query: StrictRiskScoreRequestQuery) -> [StrictRiskScoreRequest] {
        return query.apply(store.list())
    }
}
