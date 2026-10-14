import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution rollups by code.
    protocol SubstitutionRollupStore {
        func find(_ code: String) -> SubstitutionRollup?
        func save(_ item: SubstitutionRollup)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionRollupStore: SubstitutionRollupStore {
        var items: [String: SubstitutionRollup]
        var order: [String]

        init(items: [String: SubstitutionRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionRollup) {
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

        func list() -> [SubstitutionRollup] {
            var out: [SubstitutionRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionRollupStore() -> any SubstitutionRollupStore {
        return MemorySubstitutionRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionRollupStore: SubstitutionRollupStore {
        var inner: MemorySubstitutionRollupStore
        var cache: TTLCache<SubstitutionRollup>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionRollupStore, cache: TTLCache<SubstitutionRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionRollup? {
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

        func save(_ item: SubstitutionRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionRollup] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionRollupStore(_ inner: MemorySubstitutionRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionRollupStore {
        return CachedSubstitutionRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution rollups. Empty fields match all.
    final class SubstitutionRollupQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionRollup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [SubstitutionRollup]) -> [SubstitutionRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionRollups(_ store: any SubstitutionRollupStore, query: SubstitutionRollupQuery) -> [SubstitutionRollup] {
        return query.apply(store.list())
    }
}
