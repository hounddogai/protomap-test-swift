import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict dispense targets by code.
    protocol StrictDispenseTargetStore {
        func find(_ code: String) -> StrictDispenseTarget?
        func save(_ item: StrictDispenseTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDispenseTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDispenseTargetStore: StrictDispenseTargetStore {
        var items: [String: StrictDispenseTarget]
        var order: [String]

        init(items: [String: StrictDispenseTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDispenseTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDispenseTarget) {
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

        func list() -> [StrictDispenseTarget] {
            var out: [StrictDispenseTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDispenseTargetStore() -> any StrictDispenseTargetStore {
        return MemoryStrictDispenseTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDispenseTargetStore: StrictDispenseTargetStore {
        var inner: MemoryStrictDispenseTargetStore
        var cache: TTLCache<StrictDispenseTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDispenseTargetStore, cache: TTLCache<StrictDispenseTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDispenseTarget? {
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

        func save(_ item: StrictDispenseTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDispenseTarget] {
            return inner.list()
        }
    }

    static func newCachedStrictDispenseTargetStore(_ inner: MemoryStrictDispenseTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDispenseTargetStore {
        return CachedStrictDispenseTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict dispense targets. Empty fields match all.
    final class StrictDispenseTargetQuery {
        var locale: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDispenseTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictDispenseTarget]) -> [StrictDispenseTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDispenseTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDispenseTargets(_ store: any StrictDispenseTargetStore, query: StrictDispenseTargetQuery) -> [StrictDispenseTarget] {
        return query.apply(store.list())
    }
}
