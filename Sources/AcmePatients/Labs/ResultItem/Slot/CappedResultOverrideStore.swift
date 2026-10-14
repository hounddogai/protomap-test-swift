import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped result overrides by code.
    protocol CappedResultOverrideStore {
        func find(_ code: String) -> CappedResultOverride?
        func save(_ item: CappedResultOverride)
        func remove(_ code: String) -> Bool
        func list() -> [CappedResultOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedResultOverrideStore: CappedResultOverrideStore {
        var items: [String: CappedResultOverride]
        var order: [String]

        init(items: [String: CappedResultOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedResultOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedResultOverride) {
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

        func list() -> [CappedResultOverride] {
            var out: [CappedResultOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedResultOverrideStore() -> any CappedResultOverrideStore {
        return MemoryCappedResultOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedResultOverrideStore: CappedResultOverrideStore {
        var inner: MemoryCappedResultOverrideStore
        var cache: TTLCache<CappedResultOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedResultOverrideStore, cache: TTLCache<CappedResultOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedResultOverride? {
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

        func save(_ item: CappedResultOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedResultOverride] {
            return inner.list()
        }
    }

    static func newCachedCappedResultOverrideStore(_ inner: MemoryCappedResultOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedResultOverrideStore {
        return CachedCappedResultOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped result overrides. Empty fields match all.
    final class CappedResultOverrideQuery {
        var country: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedResultOverride) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [CappedResultOverride]) -> [CappedResultOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedResultOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedResultOverrides(_ store: any CappedResultOverrideStore, query: CappedResultOverrideQuery) -> [CappedResultOverride] {
        return query.apply(store.list())
    }
}
