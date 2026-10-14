import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered disclosure groups by code.
    protocol TieredDisclosureGroupStore {
        func find(_ code: String) -> TieredDisclosureGroup?
        func save(_ item: TieredDisclosureGroup)
        func remove(_ code: String) -> Bool
        func list() -> [TieredDisclosureGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredDisclosureGroupStore: TieredDisclosureGroupStore {
        var items: [String: TieredDisclosureGroup]
        var order: [String]

        init(items: [String: TieredDisclosureGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredDisclosureGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredDisclosureGroup) {
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

        func list() -> [TieredDisclosureGroup] {
            var out: [TieredDisclosureGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredDisclosureGroupStore() -> any TieredDisclosureGroupStore {
        return MemoryTieredDisclosureGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredDisclosureGroupStore: TieredDisclosureGroupStore {
        var inner: MemoryTieredDisclosureGroupStore
        var cache: TTLCache<TieredDisclosureGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredDisclosureGroupStore, cache: TTLCache<TieredDisclosureGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredDisclosureGroup? {
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

        func save(_ item: TieredDisclosureGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredDisclosureGroup] {
            return inner.list()
        }
    }

    static func newCachedTieredDisclosureGroupStore(_ inner: MemoryTieredDisclosureGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredDisclosureGroupStore {
        return CachedTieredDisclosureGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered disclosure groups. Empty fields match all.
    final class TieredDisclosureGroupQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredDisclosureGroup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [TieredDisclosureGroup]) -> [TieredDisclosureGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredDisclosureGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredDisclosureGroups(_ store: any TieredDisclosureGroupStore, query: TieredDisclosureGroupQuery) -> [TieredDisclosureGroup] {
        return query.apply(store.list())
    }
}
