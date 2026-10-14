import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted handoff exceptions by code.
    protocol WeightedHandoffExceptionStore {
        func find(_ code: String) -> WeightedHandoffException?
        func save(_ item: WeightedHandoffException)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedHandoffException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedHandoffExceptionStore: WeightedHandoffExceptionStore {
        var items: [String: WeightedHandoffException]
        var order: [String]

        init(items: [String: WeightedHandoffException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedHandoffException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedHandoffException) {
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

        func list() -> [WeightedHandoffException] {
            var out: [WeightedHandoffException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedHandoffExceptionStore() -> any WeightedHandoffExceptionStore {
        return MemoryWeightedHandoffExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedHandoffExceptionStore: WeightedHandoffExceptionStore {
        var inner: MemoryWeightedHandoffExceptionStore
        var cache: TTLCache<WeightedHandoffException>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedHandoffExceptionStore, cache: TTLCache<WeightedHandoffException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedHandoffException? {
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

        func save(_ item: WeightedHandoffException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedHandoffException] {
            return inner.list()
        }
    }

    static func newCachedWeightedHandoffExceptionStore(_ inner: MemoryWeightedHandoffExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedHandoffExceptionStore {
        return CachedWeightedHandoffExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted handoff exceptions. Empty fields match all.
    final class WeightedHandoffExceptionQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedHandoffException) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedHandoffException]) -> [WeightedHandoffException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedHandoffException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedHandoffExceptions(_ store: any WeightedHandoffExceptionStore, query: WeightedHandoffExceptionQuery) -> [WeightedHandoffException] {
        return query.apply(store.list())
    }
}
