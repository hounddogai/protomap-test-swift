import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff reservations by code.
    protocol HandoffReservationStore {
        func find(_ code: String) -> HandoffReservation?
        func save(_ item: HandoffReservation)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffReservationStore: HandoffReservationStore {
        var items: [String: HandoffReservation]
        var order: [String]

        init(items: [String: HandoffReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffReservation) {
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

        func list() -> [HandoffReservation] {
            var out: [HandoffReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffReservationStore() -> any HandoffReservationStore {
        return MemoryHandoffReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffReservationStore: HandoffReservationStore {
        var inner: MemoryHandoffReservationStore
        var cache: TTLCache<HandoffReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffReservationStore, cache: TTLCache<HandoffReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffReservation? {
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

        func save(_ item: HandoffReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffReservation] {
            return inner.list()
        }
    }

    static func newCachedHandoffReservationStore(_ inner: MemoryHandoffReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffReservationStore {
        return CachedHandoffReservationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff reservations. Empty fields match all.
    final class HandoffReservationQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffReservation]) -> [HandoffReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffReservations(_ store: any HandoffReservationStore, query: HandoffReservationQuery) -> [HandoffReservation] {
        return query.apply(store.list())
    }
}
