import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score reservations by code.
    protocol RiskScoreReservationStore {
        func find(_ code: String) -> RiskScoreReservation?
        func save(_ item: RiskScoreReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreReservationStore: RiskScoreReservationStore {
        var items: [String: RiskScoreReservation]
        var order: [String]

        init(items: [String: RiskScoreReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreReservation) {
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

        func list() -> [RiskScoreReservation] {
            var out: [RiskScoreReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreReservationStore() -> any RiskScoreReservationStore {
        return MemoryRiskScoreReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreReservationStore: RiskScoreReservationStore {
        var inner: MemoryRiskScoreReservationStore
        var cache: TTLCache<RiskScoreReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreReservationStore, cache: TTLCache<RiskScoreReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreReservation? {
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

        func save(_ item: RiskScoreReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreReservation] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreReservationStore(_ inner: MemoryRiskScoreReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreReservationStore {
        return CachedRiskScoreReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score reservations. Empty fields match all.
    final class RiskScoreReservationQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreReservation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [RiskScoreReservation]) -> [RiskScoreReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreReservations(_ store: any RiskScoreReservationStore, query: RiskScoreReservationQuery) -> [RiskScoreReservation] {
        return query.apply(store.list())
    }
}
