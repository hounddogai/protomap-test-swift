import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range tiers by code.
    protocol ReferenceRangeTierStore {
        func find(_ code: String) -> ReferenceRangeTier?
        func save(_ item: ReferenceRangeTier)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeTierStore: ReferenceRangeTierStore {
        var items: [String: ReferenceRangeTier]
        var order: [String]

        init(items: [String: ReferenceRangeTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeTier) {
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

        func list() -> [ReferenceRangeTier] {
            var out: [ReferenceRangeTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeTierStore() -> any ReferenceRangeTierStore {
        return MemoryReferenceRangeTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeTierStore: ReferenceRangeTierStore {
        var inner: MemoryReferenceRangeTierStore
        var cache: TTLCache<ReferenceRangeTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeTierStore, cache: TTLCache<ReferenceRangeTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeTier? {
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

        func save(_ item: ReferenceRangeTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeTier] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeTierStore(_ inner: MemoryReferenceRangeTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeTierStore {
        return CachedReferenceRangeTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range tiers. Empty fields match all.
    final class ReferenceRangeTierQuery {
        var locale: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCost: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeTier) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeTier]) -> [ReferenceRangeTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeTiers(_ store: any ReferenceRangeTierStore, query: ReferenceRangeTierQuery) -> [ReferenceRangeTier] {
        return query.apply(store.list())
    }
}
