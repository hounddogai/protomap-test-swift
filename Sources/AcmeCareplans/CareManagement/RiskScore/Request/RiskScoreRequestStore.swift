import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score requests by code.
    protocol RiskScoreRequestStore {
        func find(_ code: String) -> RiskScoreRequest?
        func save(_ item: RiskScoreRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreRequestStore: RiskScoreRequestStore {
        var items: [String: RiskScoreRequest]
        var order: [String]

        init(items: [String: RiskScoreRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreRequest) {
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

        func list() -> [RiskScoreRequest] {
            var out: [RiskScoreRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreRequestStore() -> any RiskScoreRequestStore {
        return MemoryRiskScoreRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreRequestStore: RiskScoreRequestStore {
        var inner: MemoryRiskScoreRequestStore
        var cache: TTLCache<RiskScoreRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreRequestStore, cache: TTLCache<RiskScoreRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreRequest? {
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

        func save(_ item: RiskScoreRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreRequest] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreRequestStore(_ inner: MemoryRiskScoreRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreRequestStore {
        return CachedRiskScoreRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score requests. Empty fields match all.
    final class RiskScoreRequestQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreRequest]) -> [RiskScoreRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreRequests(_ store: any RiskScoreRequestStore, query: RiskScoreRequestQuery) -> [RiskScoreRequest] {
        return query.apply(store.list())
    }
}
