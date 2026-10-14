import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default census reservations by code.
    protocol DefaultCensusReservationStore {
        func find(_ code: String) -> DefaultCensusReservation?
        func save(_ item: DefaultCensusReservation)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCensusReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCensusReservationStore: DefaultCensusReservationStore {
        var items: [String: DefaultCensusReservation]
        var order: [String]

        init(items: [String: DefaultCensusReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCensusReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCensusReservation) {
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

        func list() -> [DefaultCensusReservation] {
            var out: [DefaultCensusReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCensusReservationStore() -> any DefaultCensusReservationStore {
        return MemoryDefaultCensusReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCensusReservationStore: DefaultCensusReservationStore {
        var inner: MemoryDefaultCensusReservationStore
        var cache: TTLCache<DefaultCensusReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCensusReservationStore, cache: TTLCache<DefaultCensusReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCensusReservation? {
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

        func save(_ item: DefaultCensusReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCensusReservation] {
            return inner.list()
        }
    }

    static func newCachedDefaultCensusReservationStore(_ inner: MemoryDefaultCensusReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCensusReservationStore {
        return CachedDefaultCensusReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default census reservations. Empty fields match all.
    final class DefaultCensusReservationQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCensusReservation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DefaultCensusReservation]) -> [DefaultCensusReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCensusReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCensusReservations(_ store: any DefaultCensusReservationStore, query: DefaultCensusReservationQuery) -> [DefaultCensusReservation] {
        return query.apply(store.list())
    }
}
