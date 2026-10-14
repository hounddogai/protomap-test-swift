import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure targets by code.
    protocol ClosureTargetStore {
        func find(_ code: String) -> ClosureTarget?
        func save(_ item: ClosureTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureTargetStore: ClosureTargetStore {
        var items: [String: ClosureTarget]
        var order: [String]

        init(items: [String: ClosureTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureTarget) {
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

        func list() -> [ClosureTarget] {
            var out: [ClosureTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureTargetStore() -> any ClosureTargetStore {
        return MemoryClosureTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureTargetStore: ClosureTargetStore {
        var inner: MemoryClosureTargetStore
        var cache: TTLCache<ClosureTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureTargetStore, cache: TTLCache<ClosureTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureTarget? {
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

        func save(_ item: ClosureTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureTarget] {
            return inner.list()
        }
    }

    static func newCachedClosureTargetStore(_ inner: MemoryClosureTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureTargetStore {
        return CachedClosureTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure targets. Empty fields match all.
    final class ClosureTargetQuery {
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

        func matches(_ item: ClosureTarget) -> Bool {
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

        func apply(_ items: [ClosureTarget]) -> [ClosureTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureTargets(_ store: any ClosureTargetStore, query: ClosureTargetQuery) -> [ClosureTarget] {
        return query.apply(store.list())
    }
}
