import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure groups by code.
    protocol DisclosureGroupStore {
        func find(_ code: String) -> DisclosureGroup?
        func save(_ item: DisclosureGroup)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureGroupStore: DisclosureGroupStore {
        var items: [String: DisclosureGroup]
        var order: [String]

        init(items: [String: DisclosureGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureGroup) {
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

        func list() -> [DisclosureGroup] {
            var out: [DisclosureGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureGroupStore() -> any DisclosureGroupStore {
        return MemoryDisclosureGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureGroupStore: DisclosureGroupStore {
        var inner: MemoryDisclosureGroupStore
        var cache: TTLCache<DisclosureGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureGroupStore, cache: TTLCache<DisclosureGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureGroup? {
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

        func save(_ item: DisclosureGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureGroup] {
            return inner.list()
        }
    }

    static func newCachedDisclosureGroupStore(_ inner: MemoryDisclosureGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureGroupStore {
        return CachedDisclosureGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure groups. Empty fields match all.
    final class DisclosureGroupQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureGroup]) -> [DisclosureGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureGroups(_ store: any DisclosureGroupStore, query: DisclosureGroupQuery) -> [DisclosureGroup] {
        return query.apply(store.list())
    }
}
