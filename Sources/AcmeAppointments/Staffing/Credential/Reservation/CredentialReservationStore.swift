import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential reservations by code.
    protocol CredentialReservationStore {
        func find(_ code: String) -> CredentialReservation?
        func save(_ item: CredentialReservation)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialReservationStore: CredentialReservationStore {
        var items: [String: CredentialReservation]
        var order: [String]

        init(items: [String: CredentialReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialReservation) {
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

        func list() -> [CredentialReservation] {
            var out: [CredentialReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialReservationStore() -> any CredentialReservationStore {
        return MemoryCredentialReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialReservationStore: CredentialReservationStore {
        var inner: MemoryCredentialReservationStore
        var cache: TTLCache<CredentialReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialReservationStore, cache: TTLCache<CredentialReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialReservation? {
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

        func save(_ item: CredentialReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialReservation] {
            return inner.list()
        }
    }

    static func newCachedCredentialReservationStore(_ inner: MemoryCredentialReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialReservationStore {
        return CachedCredentialReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential reservations. Empty fields match all.
    final class CredentialReservationQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialReservation]) -> [CredentialReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialReservations(_ store: any CredentialReservationStore, query: CredentialReservationQuery) -> [CredentialReservation] {
        return query.apply(store.list())
    }
}
