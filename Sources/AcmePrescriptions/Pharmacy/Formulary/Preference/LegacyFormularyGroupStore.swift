import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy formulary groups by code.
    protocol LegacyFormularyGroupStore {
        func find(_ code: String) -> LegacyFormularyGroup?
        func save(_ item: LegacyFormularyGroup)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyFormularyGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyFormularyGroupStore: LegacyFormularyGroupStore {
        var items: [String: LegacyFormularyGroup]
        var order: [String]

        init(items: [String: LegacyFormularyGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyFormularyGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyFormularyGroup) {
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

        func list() -> [LegacyFormularyGroup] {
            var out: [LegacyFormularyGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyFormularyGroupStore() -> any LegacyFormularyGroupStore {
        return MemoryLegacyFormularyGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyFormularyGroupStore: LegacyFormularyGroupStore {
        var inner: MemoryLegacyFormularyGroupStore
        var cache: TTLCache<LegacyFormularyGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyFormularyGroupStore, cache: TTLCache<LegacyFormularyGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyFormularyGroup? {
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

        func save(_ item: LegacyFormularyGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyFormularyGroup] {
            return inner.list()
        }
    }

    static func newCachedLegacyFormularyGroupStore(_ inner: MemoryLegacyFormularyGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyFormularyGroupStore {
        return CachedLegacyFormularyGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy formulary groups. Empty fields match all.
    final class LegacyFormularyGroupQuery {
        var country: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyFormularyGroup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyFormularyGroup]) -> [LegacyFormularyGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyFormularyGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyFormularyGroups(_ store: any LegacyFormularyGroupStore, query: LegacyFormularyGroupQuery) -> [LegacyFormularyGroup] {
        return query.apply(store.list())
    }
}
