import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted goal entries by code.
    protocol WeightedGoalEntryStore {
        func find(_ code: String) -> WeightedGoalEntry?
        func save(_ item: WeightedGoalEntry)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedGoalEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedGoalEntryStore: WeightedGoalEntryStore {
        var items: [String: WeightedGoalEntry]
        var order: [String]

        init(items: [String: WeightedGoalEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedGoalEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedGoalEntry) {
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

        func list() -> [WeightedGoalEntry] {
            var out: [WeightedGoalEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedGoalEntryStore() -> any WeightedGoalEntryStore {
        return MemoryWeightedGoalEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedGoalEntryStore: WeightedGoalEntryStore {
        var inner: MemoryWeightedGoalEntryStore
        var cache: TTLCache<WeightedGoalEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedGoalEntryStore, cache: TTLCache<WeightedGoalEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedGoalEntry? {
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

        func save(_ item: WeightedGoalEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedGoalEntry] {
            return inner.list()
        }
    }

    static func newCachedWeightedGoalEntryStore(_ inner: MemoryWeightedGoalEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedGoalEntryStore {
        return CachedWeightedGoalEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted goal entries. Empty fields match all.
    final class WeightedGoalEntryQuery {
        var ward: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedGoalEntry) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [WeightedGoalEntry]) -> [WeightedGoalEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedGoalEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedGoalEntries(_ store: any WeightedGoalEntryStore, query: WeightedGoalEntryQuery) -> [WeightedGoalEntry] {
        return query.apply(store.list())
    }
}
