import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert reservations by code.
    protocol AlertReservationStore {
        func find(_ code: String) -> AlertReservation?
        func save(_ item: AlertReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AlertReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertReservationStore: AlertReservationStore {
        var items: [String: AlertReservation]
        var order: [String]

        init(items: [String: AlertReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertReservation) {
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

        func list() -> [AlertReservation] {
            var out: [AlertReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertReservationStore() -> any AlertReservationStore {
        return MemoryAlertReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertReservationStore: AlertReservationStore {
        var inner: MemoryAlertReservationStore
        var cache: TTLCache<AlertReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertReservationStore, cache: TTLCache<AlertReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertReservation? {
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

        func save(_ item: AlertReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertReservation] {
            return inner.list()
        }
    }

    static func newCachedAlertReservationStore(_ inner: MemoryAlertReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertReservationStore {
        return CachedAlertReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert reservations. Empty fields match all.
    final class AlertReservationQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertReservation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertReservation]) -> [AlertReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertReservations(_ store: any AlertReservationStore, query: AlertReservationQuery) -> [AlertReservation] {
        return query.apply(store.list())
    }
}
