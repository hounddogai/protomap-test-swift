import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched priority preferences by code.
    protocol BatchedPriorityPreferenceStore {
        func find(_ code: String) -> BatchedPriorityPreference?
        func save(_ item: BatchedPriorityPreference)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedPriorityPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedPriorityPreferenceStore: BatchedPriorityPreferenceStore {
        var items: [String: BatchedPriorityPreference]
        var order: [String]

        init(items: [String: BatchedPriorityPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedPriorityPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedPriorityPreference) {
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

        func list() -> [BatchedPriorityPreference] {
            var out: [BatchedPriorityPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedPriorityPreferenceStore() -> any BatchedPriorityPreferenceStore {
        return MemoryBatchedPriorityPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedPriorityPreferenceStore: BatchedPriorityPreferenceStore {
        var inner: MemoryBatchedPriorityPreferenceStore
        var cache: TTLCache<BatchedPriorityPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedPriorityPreferenceStore, cache: TTLCache<BatchedPriorityPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedPriorityPreference? {
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

        func save(_ item: BatchedPriorityPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedPriorityPreference] {
            return inner.list()
        }
    }

    static func newCachedBatchedPriorityPreferenceStore(_ inner: MemoryBatchedPriorityPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedPriorityPreferenceStore {
        return CachedBatchedPriorityPreferenceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched priority preferences. Empty fields match all.
    final class BatchedPriorityPreferenceQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedPriorityPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedPriorityPreference]) -> [BatchedPriorityPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedPriorityPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedPriorityPreferences(_ store: any BatchedPriorityPreferenceStore, query: BatchedPriorityPreferenceQuery) -> [BatchedPriorityPreference] {
        return query.apply(store.list())
    }
}
