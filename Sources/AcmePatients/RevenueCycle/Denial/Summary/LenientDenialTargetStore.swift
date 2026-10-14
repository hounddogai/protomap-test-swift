import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient denial targets by code.
    protocol LenientDenialTargetStore {
        func find(_ code: String) -> LenientDenialTarget?
        func save(_ item: LenientDenialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDenialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDenialTargetStore: LenientDenialTargetStore {
        var items: [String: LenientDenialTarget]
        var order: [String]

        init(items: [String: LenientDenialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDenialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDenialTarget) {
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

        func list() -> [LenientDenialTarget] {
            var out: [LenientDenialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDenialTargetStore() -> any LenientDenialTargetStore {
        return MemoryLenientDenialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDenialTargetStore: LenientDenialTargetStore {
        var inner: MemoryLenientDenialTargetStore
        var cache: TTLCache<LenientDenialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDenialTargetStore, cache: TTLCache<LenientDenialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDenialTarget? {
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

        func save(_ item: LenientDenialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDenialTarget] {
            return inner.list()
        }
    }

    static func newCachedLenientDenialTargetStore(_ inner: MemoryLenientDenialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDenialTargetStore {
        return CachedLenientDenialTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient denial targets. Empty fields match all.
    final class LenientDenialTargetQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDenialTarget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDenialTarget]) -> [LenientDenialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDenialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDenialTargets(_ store: any LenientDenialTargetStore, query: LenientDenialTargetQuery) -> [LenientDenialTarget] {
        return query.apply(store.list())
    }
}
