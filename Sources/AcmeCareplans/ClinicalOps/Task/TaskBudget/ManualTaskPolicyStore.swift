import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual task policies by code.
    protocol ManualTaskPolicyStore {
        func find(_ code: String) -> ManualTaskPolicy?
        func save(_ item: ManualTaskPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ManualTaskPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualTaskPolicyStore: ManualTaskPolicyStore {
        var items: [String: ManualTaskPolicy]
        var order: [String]

        init(items: [String: ManualTaskPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualTaskPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualTaskPolicy) {
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

        func list() -> [ManualTaskPolicy] {
            var out: [ManualTaskPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualTaskPolicyStore() -> any ManualTaskPolicyStore {
        return MemoryManualTaskPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualTaskPolicyStore: ManualTaskPolicyStore {
        var inner: MemoryManualTaskPolicyStore
        var cache: TTLCache<ManualTaskPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualTaskPolicyStore, cache: TTLCache<ManualTaskPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualTaskPolicy? {
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

        func save(_ item: ManualTaskPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualTaskPolicy] {
            return inner.list()
        }
    }

    static func newCachedManualTaskPolicyStore(_ inner: MemoryManualTaskPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualTaskPolicyStore {
        return CachedManualTaskPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual task policies. Empty fields match all.
    final class ManualTaskPolicyQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualTaskPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualTaskPolicy]) -> [ManualTaskPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualTaskPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualTaskPolicies(_ store: any ManualTaskPolicyStore, query: ManualTaskPolicyQuery) -> [ManualTaskPolicy] {
        return query.apply(store.list())
    }
}
