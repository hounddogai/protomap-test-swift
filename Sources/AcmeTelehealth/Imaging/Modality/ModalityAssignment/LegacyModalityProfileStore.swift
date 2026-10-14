import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy modality profiles by code.
    protocol LegacyModalityProfileStore {
        func find(_ code: String) -> LegacyModalityProfile?
        func save(_ item: LegacyModalityProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyModalityProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyModalityProfileStore: LegacyModalityProfileStore {
        var items: [String: LegacyModalityProfile]
        var order: [String]

        init(items: [String: LegacyModalityProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyModalityProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyModalityProfile) {
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

        func list() -> [LegacyModalityProfile] {
            var out: [LegacyModalityProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyModalityProfileStore() -> any LegacyModalityProfileStore {
        return MemoryLegacyModalityProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyModalityProfileStore: LegacyModalityProfileStore {
        var inner: MemoryLegacyModalityProfileStore
        var cache: TTLCache<LegacyModalityProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyModalityProfileStore, cache: TTLCache<LegacyModalityProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyModalityProfile? {
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

        func save(_ item: LegacyModalityProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyModalityProfile] {
            return inner.list()
        }
    }

    static func newCachedLegacyModalityProfileStore(_ inner: MemoryLegacyModalityProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyModalityProfileStore {
        return CachedLegacyModalityProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy modality profiles. Empty fields match all.
    final class LegacyModalityProfileQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyModalityProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyModalityProfile]) -> [LegacyModalityProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyModalityProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyModalityProfiles(_ store: any LegacyModalityProfileStore, query: LegacyModalityProfileQuery) -> [LegacyModalityProfile] {
        return query.apply(store.list())
    }
}
