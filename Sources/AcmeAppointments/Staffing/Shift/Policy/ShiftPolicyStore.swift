import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift policies by code.
    protocol ShiftPolicyStore {
        func find(_ code: String) -> ShiftPolicy?
        func save(_ item: ShiftPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftPolicyStore: ShiftPolicyStore {
        var items: [String: ShiftPolicy]
        var order: [String]

        init(items: [String: ShiftPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftPolicy) {
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

        func list() -> [ShiftPolicy] {
            var out: [ShiftPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftPolicyStore() -> any ShiftPolicyStore {
        return MemoryShiftPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftPolicyStore: ShiftPolicyStore {
        var inner: MemoryShiftPolicyStore
        var cache: TTLCache<ShiftPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftPolicyStore, cache: TTLCache<ShiftPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftPolicy? {
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

        func save(_ item: ShiftPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftPolicy] {
            return inner.list()
        }
    }

    static func newCachedShiftPolicyStore(_ inner: MemoryShiftPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftPolicyStore {
        return CachedShiftPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift policies. Empty fields match all.
    final class ShiftPolicyQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftPolicy]) -> [ShiftPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftPolicies(_ store: any ShiftPolicyStore, query: ShiftPolicyQuery) -> [ShiftPolicy] {
        return query.apply(store.list())
    }
}
