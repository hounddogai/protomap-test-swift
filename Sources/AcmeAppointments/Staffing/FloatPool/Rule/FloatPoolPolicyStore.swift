import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool policies by code.
    protocol FloatPoolPolicyStore {
        func find(_ code: String) -> FloatPoolPolicy?
        func save(_ item: FloatPoolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolPolicyStore: FloatPoolPolicyStore {
        var items: [String: FloatPoolPolicy]
        var order: [String]

        init(items: [String: FloatPoolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolPolicy) {
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

        func list() -> [FloatPoolPolicy] {
            var out: [FloatPoolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolPolicyStore() -> any FloatPoolPolicyStore {
        return MemoryFloatPoolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolPolicyStore: FloatPoolPolicyStore {
        var inner: MemoryFloatPoolPolicyStore
        var cache: TTLCache<FloatPoolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolPolicyStore, cache: TTLCache<FloatPoolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolPolicy? {
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

        func save(_ item: FloatPoolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolPolicy] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolPolicyStore(_ inner: MemoryFloatPoolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolPolicyStore {
        return CachedFloatPoolPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool policies. Empty fields match all.
    final class FloatPoolPolicyQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolPolicy]) -> [FloatPoolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolPolicies(_ store: any FloatPoolPolicyStore, query: FloatPoolPolicyQuery) -> [FloatPoolPolicy] {
        return query.apply(store.list())
    }
}
