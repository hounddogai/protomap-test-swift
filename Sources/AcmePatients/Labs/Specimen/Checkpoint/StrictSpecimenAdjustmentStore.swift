import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict specimen adjustments by code.
    protocol StrictSpecimenAdjustmentStore {
        func find(_ code: String) -> StrictSpecimenAdjustment?
        func save(_ item: StrictSpecimenAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSpecimenAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSpecimenAdjustmentStore: StrictSpecimenAdjustmentStore {
        var items: [String: StrictSpecimenAdjustment]
        var order: [String]

        init(items: [String: StrictSpecimenAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSpecimenAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSpecimenAdjustment) {
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

        func list() -> [StrictSpecimenAdjustment] {
            var out: [StrictSpecimenAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSpecimenAdjustmentStore() -> any StrictSpecimenAdjustmentStore {
        return MemoryStrictSpecimenAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSpecimenAdjustmentStore: StrictSpecimenAdjustmentStore {
        var inner: MemoryStrictSpecimenAdjustmentStore
        var cache: TTLCache<StrictSpecimenAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSpecimenAdjustmentStore, cache: TTLCache<StrictSpecimenAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSpecimenAdjustment? {
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

        func save(_ item: StrictSpecimenAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSpecimenAdjustment] {
            return inner.list()
        }
    }

    static func newCachedStrictSpecimenAdjustmentStore(_ inner: MemoryStrictSpecimenAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSpecimenAdjustmentStore {
        return CachedStrictSpecimenAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict specimen adjustments. Empty fields match all.
    final class StrictSpecimenAdjustmentQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSpecimenAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSpecimenAdjustment]) -> [StrictSpecimenAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSpecimenAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSpecimenAdjustments(_ store: any StrictSpecimenAdjustmentStore, query: StrictSpecimenAdjustmentQuery) -> [StrictSpecimenAdjustment] {
        return query.apply(store.list())
    }
}
