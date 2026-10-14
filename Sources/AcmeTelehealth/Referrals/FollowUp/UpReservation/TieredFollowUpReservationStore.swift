import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered follow up reservations by code.
    protocol TieredFollowUpReservationStore {
        func find(_ code: String) -> TieredFollowUpReservation?
        func save(_ item: TieredFollowUpReservation)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFollowUpReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFollowUpReservationStore: TieredFollowUpReservationStore {
        var items: [String: TieredFollowUpReservation]
        var order: [String]

        init(items: [String: TieredFollowUpReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFollowUpReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFollowUpReservation) {
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

        func list() -> [TieredFollowUpReservation] {
            var out: [TieredFollowUpReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFollowUpReservationStore() -> any TieredFollowUpReservationStore {
        return MemoryTieredFollowUpReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFollowUpReservationStore: TieredFollowUpReservationStore {
        var inner: MemoryTieredFollowUpReservationStore
        var cache: TTLCache<TieredFollowUpReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFollowUpReservationStore, cache: TTLCache<TieredFollowUpReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFollowUpReservation? {
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

        func save(_ item: TieredFollowUpReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFollowUpReservation] {
            return inner.list()
        }
    }

    static func newCachedTieredFollowUpReservationStore(_ inner: MemoryTieredFollowUpReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFollowUpReservationStore {
        return CachedTieredFollowUpReservationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered follow up reservations. Empty fields match all.
    final class TieredFollowUpReservationQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFollowUpReservation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [TieredFollowUpReservation]) -> [TieredFollowUpReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFollowUpReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFollowUpReservations(_ store: any TieredFollowUpReservationStore, query: TieredFollowUpReservationQuery) -> [TieredFollowUpReservation] {
        return query.apply(store.list())
    }
}
