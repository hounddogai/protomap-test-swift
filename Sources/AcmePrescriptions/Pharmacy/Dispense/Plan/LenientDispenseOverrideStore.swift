import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient dispense overrides by code.
    protocol LenientDispenseOverrideStore {
        func find(_ code: String) -> LenientDispenseOverride?
        func save(_ item: LenientDispenseOverride)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDispenseOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDispenseOverrideStore: LenientDispenseOverrideStore {
        var items: [String: LenientDispenseOverride]
        var order: [String]

        init(items: [String: LenientDispenseOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDispenseOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDispenseOverride) {
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

        func list() -> [LenientDispenseOverride] {
            var out: [LenientDispenseOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDispenseOverrideStore() -> any LenientDispenseOverrideStore {
        return MemoryLenientDispenseOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDispenseOverrideStore: LenientDispenseOverrideStore {
        var inner: MemoryLenientDispenseOverrideStore
        var cache: TTLCache<LenientDispenseOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDispenseOverrideStore, cache: TTLCache<LenientDispenseOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDispenseOverride? {
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

        func save(_ item: LenientDispenseOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDispenseOverride] {
            return inner.list()
        }
    }

    static func newCachedLenientDispenseOverrideStore(_ inner: MemoryLenientDispenseOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDispenseOverrideStore {
        return CachedLenientDispenseOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient dispense overrides. Empty fields match all.
    final class LenientDispenseOverrideQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDispenseOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDispenseOverride]) -> [LenientDispenseOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDispenseOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDispenseOverrides(_ store: any LenientDispenseOverrideStore, query: LenientDispenseOverrideQuery) -> [LenientDispenseOverride] {
        return query.apply(store.list())
    }
}
