import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol reservations by code.
    protocol CareProtocolReservationStore {
        func find(_ code: String) -> CareProtocolReservation?
        func save(_ item: CareProtocolReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolReservationStore: CareProtocolReservationStore {
        var items: [String: CareProtocolReservation]
        var order: [String]

        init(items: [String: CareProtocolReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolReservation) {
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

        func list() -> [CareProtocolReservation] {
            var out: [CareProtocolReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolReservationStore() -> any CareProtocolReservationStore {
        return MemoryCareProtocolReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolReservationStore: CareProtocolReservationStore {
        var inner: MemoryCareProtocolReservationStore
        var cache: TTLCache<CareProtocolReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolReservationStore, cache: TTLCache<CareProtocolReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolReservation? {
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

        func save(_ item: CareProtocolReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolReservation] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolReservationStore(_ inner: MemoryCareProtocolReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolReservationStore {
        return CachedCareProtocolReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol reservations. Empty fields match all.
    final class CareProtocolReservationQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolReservation]) -> [CareProtocolReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolReservations(_ store: any CareProtocolReservationStore, query: CareProtocolReservationQuery) -> [CareProtocolReservation] {
        return query.apply(store.list())
    }
}
