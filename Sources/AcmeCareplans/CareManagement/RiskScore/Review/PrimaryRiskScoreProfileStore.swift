import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary risk score profiles by code.
    protocol PrimaryRiskScoreProfileStore {
        func find(_ code: String) -> PrimaryRiskScoreProfile?
        func save(_ item: PrimaryRiskScoreProfile)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRiskScoreProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRiskScoreProfileStore: PrimaryRiskScoreProfileStore {
        var items: [String: PrimaryRiskScoreProfile]
        var order: [String]

        init(items: [String: PrimaryRiskScoreProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRiskScoreProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRiskScoreProfile) {
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

        func list() -> [PrimaryRiskScoreProfile] {
            var out: [PrimaryRiskScoreProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRiskScoreProfileStore() -> any PrimaryRiskScoreProfileStore {
        return MemoryPrimaryRiskScoreProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRiskScoreProfileStore: PrimaryRiskScoreProfileStore {
        var inner: MemoryPrimaryRiskScoreProfileStore
        var cache: TTLCache<PrimaryRiskScoreProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRiskScoreProfileStore, cache: TTLCache<PrimaryRiskScoreProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRiskScoreProfile? {
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

        func save(_ item: PrimaryRiskScoreProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRiskScoreProfile] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRiskScoreProfileStore(_ inner: MemoryPrimaryRiskScoreProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRiskScoreProfileStore {
        return CachedPrimaryRiskScoreProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary risk score profiles. Empty fields match all.
    final class PrimaryRiskScoreProfileQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRiskScoreProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRiskScoreProfile]) -> [PrimaryRiskScoreProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRiskScoreProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRiskScoreProfiles(_ store: any PrimaryRiskScoreProfileStore, query: PrimaryRiskScoreProfileQuery) -> [PrimaryRiskScoreProfile] {
        return query.apply(store.list())
    }
}
