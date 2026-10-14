import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched substitution policies by code.
    protocol BatchedSubstitutionPolicyStore {
        func find(_ code: String) -> BatchedSubstitutionPolicy?
        func save(_ item: BatchedSubstitutionPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSubstitutionPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSubstitutionPolicyStore: BatchedSubstitutionPolicyStore {
        var items: [String: BatchedSubstitutionPolicy]
        var order: [String]

        init(items: [String: BatchedSubstitutionPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSubstitutionPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSubstitutionPolicy) {
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

        func list() -> [BatchedSubstitutionPolicy] {
            var out: [BatchedSubstitutionPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSubstitutionPolicyStore() -> any BatchedSubstitutionPolicyStore {
        return MemoryBatchedSubstitutionPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSubstitutionPolicyStore: BatchedSubstitutionPolicyStore {
        var inner: MemoryBatchedSubstitutionPolicyStore
        var cache: TTLCache<BatchedSubstitutionPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSubstitutionPolicyStore, cache: TTLCache<BatchedSubstitutionPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSubstitutionPolicy? {
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

        func save(_ item: BatchedSubstitutionPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSubstitutionPolicy] {
            return inner.list()
        }
    }

    static func newCachedBatchedSubstitutionPolicyStore(_ inner: MemoryBatchedSubstitutionPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSubstitutionPolicyStore {
        return CachedBatchedSubstitutionPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched substitution policies. Empty fields match all.
    final class BatchedSubstitutionPolicyQuery {
        var country: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSubstitutionPolicy) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSubstitutionPolicy]) -> [BatchedSubstitutionPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSubstitutionPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSubstitutionPolicies(_ store: any BatchedSubstitutionPolicyStore, query: BatchedSubstitutionPolicyQuery) -> [BatchedSubstitutionPolicy] {
        return query.apply(store.list())
    }
}
