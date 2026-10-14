import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered priority reservations by code.
    protocol TieredPriorityReservationStore {
        func find(_ code: String) -> TieredPriorityReservation?
        func save(_ item: TieredPriorityReservation)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPriorityReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPriorityReservationStore: TieredPriorityReservationStore {
        var items: [String: TieredPriorityReservation]
        var order: [String]

        init(items: [String: TieredPriorityReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPriorityReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPriorityReservation) {
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

        func list() -> [TieredPriorityReservation] {
            var out: [TieredPriorityReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPriorityReservationStore() -> any TieredPriorityReservationStore {
        return MemoryTieredPriorityReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPriorityReservationStore: TieredPriorityReservationStore {
        var inner: MemoryTieredPriorityReservationStore
        var cache: TTLCache<TieredPriorityReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPriorityReservationStore, cache: TTLCache<TieredPriorityReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPriorityReservation? {
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

        func save(_ item: TieredPriorityReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPriorityReservation] {
            return inner.list()
        }
    }

    static func newCachedTieredPriorityReservationStore(_ inner: MemoryTieredPriorityReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPriorityReservationStore {
        return CachedTieredPriorityReservationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered priority reservations. Empty fields match all.
    final class TieredPriorityReservationQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPriorityReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPriorityReservation]) -> [TieredPriorityReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPriorityReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPriorityReservations(_ store: any TieredPriorityReservationStore, query: TieredPriorityReservationQuery) -> [TieredPriorityReservation] {
        return query.apply(store.list())
    }
}
