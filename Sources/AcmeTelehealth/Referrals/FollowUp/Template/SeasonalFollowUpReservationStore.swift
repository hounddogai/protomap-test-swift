import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal follow up reservations by code.
    protocol SeasonalFollowUpReservationStore {
        func find(_ code: String) -> SeasonalFollowUpReservation?
        func save(_ item: SeasonalFollowUpReservation)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalFollowUpReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalFollowUpReservationStore: SeasonalFollowUpReservationStore {
        var items: [String: SeasonalFollowUpReservation]
        var order: [String]

        init(items: [String: SeasonalFollowUpReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalFollowUpReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalFollowUpReservation) {
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

        func list() -> [SeasonalFollowUpReservation] {
            var out: [SeasonalFollowUpReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalFollowUpReservationStore() -> any SeasonalFollowUpReservationStore {
        return MemorySeasonalFollowUpReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalFollowUpReservationStore: SeasonalFollowUpReservationStore {
        var inner: MemorySeasonalFollowUpReservationStore
        var cache: TTLCache<SeasonalFollowUpReservation>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalFollowUpReservationStore, cache: TTLCache<SeasonalFollowUpReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalFollowUpReservation? {
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

        func save(_ item: SeasonalFollowUpReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalFollowUpReservation] {
            return inner.list()
        }
    }

    static func newCachedSeasonalFollowUpReservationStore(_ inner: MemorySeasonalFollowUpReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalFollowUpReservationStore {
        return CachedSeasonalFollowUpReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal follow up reservations. Empty fields match all.
    final class SeasonalFollowUpReservationQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalFollowUpReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalFollowUpReservation]) -> [SeasonalFollowUpReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalFollowUpReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalFollowUpReservations(_ store: any SeasonalFollowUpReservationStore, query: SeasonalFollowUpReservationQuery) -> [SeasonalFollowUpReservation] {
        return query.apply(store.list())
    }
}
