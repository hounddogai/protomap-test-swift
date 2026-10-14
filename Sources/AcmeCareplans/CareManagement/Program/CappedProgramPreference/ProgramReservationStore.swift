import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program reservations by code.
    protocol ProgramReservationStore {
        func find(_ code: String) -> ProgramReservation?
        func save(_ item: ProgramReservation)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramReservationStore: ProgramReservationStore {
        var items: [String: ProgramReservation]
        var order: [String]

        init(items: [String: ProgramReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramReservation) {
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

        func list() -> [ProgramReservation] {
            var out: [ProgramReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramReservationStore() -> any ProgramReservationStore {
        return MemoryProgramReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramReservationStore: ProgramReservationStore {
        var inner: MemoryProgramReservationStore
        var cache: TTLCache<ProgramReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramReservationStore, cache: TTLCache<ProgramReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramReservation? {
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

        func save(_ item: ProgramReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramReservation] {
            return inner.list()
        }
    }

    static func newCachedProgramReservationStore(_ inner: MemoryProgramReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramReservationStore {
        return CachedProgramReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program reservations. Empty fields match all.
    final class ProgramReservationQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramReservation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ProgramReservation]) -> [ProgramReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramReservations(_ store: any ProgramReservationStore, query: ProgramReservationQuery) -> [ProgramReservation] {
        return query.apply(store.list())
    }
}
