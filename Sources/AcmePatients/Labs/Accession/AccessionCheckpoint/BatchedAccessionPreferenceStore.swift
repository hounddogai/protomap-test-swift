import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched accession preferences by code.
    protocol BatchedAccessionPreferenceStore {
        func find(_ code: String) -> BatchedAccessionPreference?
        func save(_ item: BatchedAccessionPreference)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAccessionPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAccessionPreferenceStore: BatchedAccessionPreferenceStore {
        var items: [String: BatchedAccessionPreference]
        var order: [String]

        init(items: [String: BatchedAccessionPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAccessionPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAccessionPreference) {
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

        func list() -> [BatchedAccessionPreference] {
            var out: [BatchedAccessionPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAccessionPreferenceStore() -> any BatchedAccessionPreferenceStore {
        return MemoryBatchedAccessionPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAccessionPreferenceStore: BatchedAccessionPreferenceStore {
        var inner: MemoryBatchedAccessionPreferenceStore
        var cache: TTLCache<BatchedAccessionPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAccessionPreferenceStore, cache: TTLCache<BatchedAccessionPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAccessionPreference? {
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

        func save(_ item: BatchedAccessionPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAccessionPreference] {
            return inner.list()
        }
    }

    static func newCachedBatchedAccessionPreferenceStore(_ inner: MemoryBatchedAccessionPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAccessionPreferenceStore {
        return CachedBatchedAccessionPreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched accession preferences. Empty fields match all.
    final class BatchedAccessionPreferenceQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAccessionPreference) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAccessionPreference]) -> [BatchedAccessionPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAccessionPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAccessionPreferences(_ store: any BatchedAccessionPreferenceStore, query: BatchedAccessionPreferenceQuery) -> [BatchedAccessionPreference] {
        return query.apply(store.list())
    }
}
