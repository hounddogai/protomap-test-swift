import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional accession reservations by code.
    protocol RegionalAccessionReservationStore {
        func find(_ code: String) -> RegionalAccessionReservation?
        func save(_ item: RegionalAccessionReservation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAccessionReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAccessionReservationStore: RegionalAccessionReservationStore {
        var items: [String: RegionalAccessionReservation]
        var order: [String]

        init(items: [String: RegionalAccessionReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAccessionReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAccessionReservation) {
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

        func list() -> [RegionalAccessionReservation] {
            var out: [RegionalAccessionReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAccessionReservationStore() -> any RegionalAccessionReservationStore {
        return MemoryRegionalAccessionReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAccessionReservationStore: RegionalAccessionReservationStore {
        var inner: MemoryRegionalAccessionReservationStore
        var cache: TTLCache<RegionalAccessionReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAccessionReservationStore, cache: TTLCache<RegionalAccessionReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAccessionReservation? {
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

        func save(_ item: RegionalAccessionReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAccessionReservation] {
            return inner.list()
        }
    }

    static func newCachedRegionalAccessionReservationStore(_ inner: MemoryRegionalAccessionReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAccessionReservationStore {
        return CachedRegionalAccessionReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional accession reservations. Empty fields match all.
    final class RegionalAccessionReservationQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAccessionReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAccessionReservation]) -> [RegionalAccessionReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAccessionReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAccessionReservations(_ store: any RegionalAccessionReservationStore, query: RegionalAccessionReservationQuery) -> [RegionalAccessionReservation] {
        return query.apply(store.list())
    }
}
