import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen overrides by code.
    protocol SpecimenOverrideStore {
        func find(_ code: String) -> SpecimenOverride?
        func save(_ item: SpecimenOverride)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenOverrideStore: SpecimenOverrideStore {
        var items: [String: SpecimenOverride]
        var order: [String]

        init(items: [String: SpecimenOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenOverride) {
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

        func list() -> [SpecimenOverride] {
            var out: [SpecimenOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenOverrideStore() -> any SpecimenOverrideStore {
        return MemorySpecimenOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenOverrideStore: SpecimenOverrideStore {
        var inner: MemorySpecimenOverrideStore
        var cache: TTLCache<SpecimenOverride>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenOverrideStore, cache: TTLCache<SpecimenOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenOverride? {
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

        func save(_ item: SpecimenOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenOverride] {
            return inner.list()
        }
    }

    static func newCachedSpecimenOverrideStore(_ inner: MemorySpecimenOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenOverrideStore {
        return CachedSpecimenOverrideStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen overrides. Empty fields match all.
    final class SpecimenOverrideQuery {
        var locale: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SpecimenOverride]) -> [SpecimenOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenOverrides(_ store: any SpecimenOverrideStore, query: SpecimenOverrideQuery) -> [SpecimenOverride] {
        return query.apply(store.list())
    }
}
