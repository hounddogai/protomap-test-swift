import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy claim profiles by code.
    protocol LegacyClaimProfileStore {
        func find(_ code: String) -> LegacyClaimProfile?
        func save(_ item: LegacyClaimProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyClaimProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyClaimProfileStore: LegacyClaimProfileStore {
        var items: [String: LegacyClaimProfile]
        var order: [String]

        init(items: [String: LegacyClaimProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyClaimProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyClaimProfile) {
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

        func list() -> [LegacyClaimProfile] {
            var out: [LegacyClaimProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyClaimProfileStore() -> any LegacyClaimProfileStore {
        return MemoryLegacyClaimProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyClaimProfileStore: LegacyClaimProfileStore {
        var inner: MemoryLegacyClaimProfileStore
        var cache: TTLCache<LegacyClaimProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyClaimProfileStore, cache: TTLCache<LegacyClaimProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyClaimProfile? {
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

        func save(_ item: LegacyClaimProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyClaimProfile] {
            return inner.list()
        }
    }

    static func newCachedLegacyClaimProfileStore(_ inner: MemoryLegacyClaimProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyClaimProfileStore {
        return CachedLegacyClaimProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy claim profiles. Empty fields match all.
    final class LegacyClaimProfileQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyClaimProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyClaimProfile]) -> [LegacyClaimProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyClaimProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyClaimProfiles(_ store: any LegacyClaimProfileStore, query: LegacyClaimProfileQuery) -> [LegacyClaimProfile] {
        return query.apply(store.list())
    }
}
