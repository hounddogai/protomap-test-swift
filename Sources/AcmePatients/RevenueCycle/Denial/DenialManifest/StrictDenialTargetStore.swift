import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict denial targets by code.
    protocol StrictDenialTargetStore {
        func find(_ code: String) -> StrictDenialTarget?
        func save(_ item: StrictDenialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDenialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDenialTargetStore: StrictDenialTargetStore {
        var items: [String: StrictDenialTarget]
        var order: [String]

        init(items: [String: StrictDenialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDenialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDenialTarget) {
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

        func list() -> [StrictDenialTarget] {
            var out: [StrictDenialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDenialTargetStore() -> any StrictDenialTargetStore {
        return MemoryStrictDenialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDenialTargetStore: StrictDenialTargetStore {
        var inner: MemoryStrictDenialTargetStore
        var cache: TTLCache<StrictDenialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDenialTargetStore, cache: TTLCache<StrictDenialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDenialTarget? {
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

        func save(_ item: StrictDenialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDenialTarget] {
            return inner.list()
        }
    }

    static func newCachedStrictDenialTargetStore(_ inner: MemoryStrictDenialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDenialTargetStore {
        return CachedStrictDenialTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict denial targets. Empty fields match all.
    final class StrictDenialTargetQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDenialTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [StrictDenialTarget]) -> [StrictDenialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDenialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDenialTargets(_ store: any StrictDenialTargetStore, query: StrictDenialTargetQuery) -> [StrictDenialTarget] {
        return query.apply(store.list())
    }
}
