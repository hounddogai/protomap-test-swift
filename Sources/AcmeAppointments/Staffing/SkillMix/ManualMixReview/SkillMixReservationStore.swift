import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix reservations by code.
    protocol SkillMixReservationStore {
        func find(_ code: String) -> SkillMixReservation?
        func save(_ item: SkillMixReservation)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixReservationStore: SkillMixReservationStore {
        var items: [String: SkillMixReservation]
        var order: [String]

        init(items: [String: SkillMixReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixReservation) {
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

        func list() -> [SkillMixReservation] {
            var out: [SkillMixReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixReservationStore() -> any SkillMixReservationStore {
        return MemorySkillMixReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixReservationStore: SkillMixReservationStore {
        var inner: MemorySkillMixReservationStore
        var cache: TTLCache<SkillMixReservation>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixReservationStore, cache: TTLCache<SkillMixReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixReservation? {
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

        func save(_ item: SkillMixReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixReservation] {
            return inner.list()
        }
    }

    static func newCachedSkillMixReservationStore(_ inner: MemorySkillMixReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixReservationStore {
        return CachedSkillMixReservationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix reservations. Empty fields match all.
    final class SkillMixReservationQuery {
        var source: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixReservation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [SkillMixReservation]) -> [SkillMixReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixReservations(_ store: any SkillMixReservationStore, query: SkillMixReservationQuery) -> [SkillMixReservation] {
        return query.apply(store.list())
    }
}
