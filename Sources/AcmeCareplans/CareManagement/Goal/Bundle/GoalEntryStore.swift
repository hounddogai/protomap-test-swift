import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal entries by code.
    protocol GoalEntryStore {
        func find(_ code: String) -> GoalEntry?
        func save(_ item: GoalEntry)
        func remove(_ code: String) -> Bool
        func list() -> [GoalEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalEntryStore: GoalEntryStore {
        var items: [String: GoalEntry]
        var order: [String]

        init(items: [String: GoalEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalEntry) {
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

        func list() -> [GoalEntry] {
            var out: [GoalEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalEntryStore() -> any GoalEntryStore {
        return MemoryGoalEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalEntryStore: GoalEntryStore {
        var inner: MemoryGoalEntryStore
        var cache: TTLCache<GoalEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalEntryStore, cache: TTLCache<GoalEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalEntry? {
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

        func save(_ item: GoalEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalEntry] {
            return inner.list()
        }
    }

    static func newCachedGoalEntryStore(_ inner: MemoryGoalEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalEntryStore {
        return CachedGoalEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal entries. Empty fields match all.
    final class GoalEntryQuery {
        var facility: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCopay: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalEntry) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalEntry]) -> [GoalEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalEntries(_ store: any GoalEntryStore, query: GoalEntryQuery) -> [GoalEntry] {
        return query.apply(store.list())
    }
}
