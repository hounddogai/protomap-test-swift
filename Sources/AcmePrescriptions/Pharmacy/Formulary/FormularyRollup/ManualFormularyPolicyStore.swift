import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual formulary policies by code.
    protocol ManualFormularyPolicyStore {
        func find(_ code: String) -> ManualFormularyPolicy?
        func save(_ item: ManualFormularyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFormularyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFormularyPolicyStore: ManualFormularyPolicyStore {
        var items: [String: ManualFormularyPolicy]
        var order: [String]

        init(items: [String: ManualFormularyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFormularyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFormularyPolicy) {
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

        func list() -> [ManualFormularyPolicy] {
            var out: [ManualFormularyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFormularyPolicyStore() -> any ManualFormularyPolicyStore {
        return MemoryManualFormularyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFormularyPolicyStore: ManualFormularyPolicyStore {
        var inner: MemoryManualFormularyPolicyStore
        var cache: TTLCache<ManualFormularyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFormularyPolicyStore, cache: TTLCache<ManualFormularyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFormularyPolicy? {
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

        func save(_ item: ManualFormularyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFormularyPolicy] {
            return inner.list()
        }
    }

    static func newCachedManualFormularyPolicyStore(_ inner: MemoryManualFormularyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFormularyPolicyStore {
        return CachedManualFormularyPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual formulary policies. Empty fields match all.
    final class ManualFormularyPolicyQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFormularyPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualFormularyPolicy]) -> [ManualFormularyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFormularyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFormularyPolicies(_ store: any ManualFormularyPolicyStore, query: ManualFormularyPolicyQuery) -> [ManualFormularyPolicy] {
        return query.apply(store.list())
    }
}
