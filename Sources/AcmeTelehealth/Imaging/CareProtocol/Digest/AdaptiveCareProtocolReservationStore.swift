import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive care protocol reservations by code.
    protocol AdaptiveCareProtocolReservationStore {
        func find(_ code: String) -> AdaptiveCareProtocolReservation?
        func save(_ item: AdaptiveCareProtocolReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCareProtocolReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCareProtocolReservationStore: AdaptiveCareProtocolReservationStore {
        var items: [String: AdaptiveCareProtocolReservation]
        var order: [String]

        init(items: [String: AdaptiveCareProtocolReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCareProtocolReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCareProtocolReservation) {
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

        func list() -> [AdaptiveCareProtocolReservation] {
            var out: [AdaptiveCareProtocolReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCareProtocolReservationStore() -> any AdaptiveCareProtocolReservationStore {
        return MemoryAdaptiveCareProtocolReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCareProtocolReservationStore: AdaptiveCareProtocolReservationStore {
        var inner: MemoryAdaptiveCareProtocolReservationStore
        var cache: TTLCache<AdaptiveCareProtocolReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCareProtocolReservationStore, cache: TTLCache<AdaptiveCareProtocolReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCareProtocolReservation? {
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

        func save(_ item: AdaptiveCareProtocolReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCareProtocolReservation] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCareProtocolReservationStore(_ inner: MemoryAdaptiveCareProtocolReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCareProtocolReservationStore {
        return CachedAdaptiveCareProtocolReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive care protocol reservations. Empty fields match all.
    final class AdaptiveCareProtocolReservationQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCareProtocolReservation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AdaptiveCareProtocolReservation]) -> [AdaptiveCareProtocolReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCareProtocolReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCareProtocolReservations(_ store: any AdaptiveCareProtocolReservationStore, query: AdaptiveCareProtocolReservationQuery) -> [AdaptiveCareProtocolReservation] {
        return query.apply(store.list())
    }
}
