import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched risk score preferences by code.
    protocol BatchedRiskScorePreferenceStore {
        func find(_ code: String) -> BatchedRiskScorePreference?
        func save(_ item: BatchedRiskScorePreference)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRiskScorePreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRiskScorePreferenceStore: BatchedRiskScorePreferenceStore {
        var items: [String: BatchedRiskScorePreference]
        var order: [String]

        init(items: [String: BatchedRiskScorePreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRiskScorePreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRiskScorePreference) {
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

        func list() -> [BatchedRiskScorePreference] {
            var out: [BatchedRiskScorePreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRiskScorePreferenceStore() -> any BatchedRiskScorePreferenceStore {
        return MemoryBatchedRiskScorePreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRiskScorePreferenceStore: BatchedRiskScorePreferenceStore {
        var inner: MemoryBatchedRiskScorePreferenceStore
        var cache: TTLCache<BatchedRiskScorePreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRiskScorePreferenceStore, cache: TTLCache<BatchedRiskScorePreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRiskScorePreference? {
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

        func save(_ item: BatchedRiskScorePreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRiskScorePreference] {
            return inner.list()
        }
    }

    static func newCachedBatchedRiskScorePreferenceStore(_ inner: MemoryBatchedRiskScorePreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRiskScorePreferenceStore {
        return CachedBatchedRiskScorePreferenceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched risk score preferences. Empty fields match all.
    final class BatchedRiskScorePreferenceQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRiskScorePreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRiskScorePreference]) -> [BatchedRiskScorePreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRiskScorePreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRiskScorePreferences(_ store: any BatchedRiskScorePreferenceStore, query: BatchedRiskScorePreferenceQuery) -> [BatchedRiskScorePreference] {
        return query.apply(store.list())
    }
}
