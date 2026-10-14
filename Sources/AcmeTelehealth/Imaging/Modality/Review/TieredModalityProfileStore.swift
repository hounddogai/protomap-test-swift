import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered modality profiles by code.
    protocol TieredModalityProfileStore {
        func find(_ code: String) -> TieredModalityProfile?
        func save(_ item: TieredModalityProfile)
        func remove(_ code: String) -> Bool
        func list() -> [TieredModalityProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredModalityProfileStore: TieredModalityProfileStore {
        var items: [String: TieredModalityProfile]
        var order: [String]

        init(items: [String: TieredModalityProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredModalityProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredModalityProfile) {
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

        func list() -> [TieredModalityProfile] {
            var out: [TieredModalityProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredModalityProfileStore() -> any TieredModalityProfileStore {
        return MemoryTieredModalityProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredModalityProfileStore: TieredModalityProfileStore {
        var inner: MemoryTieredModalityProfileStore
        var cache: TTLCache<TieredModalityProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredModalityProfileStore, cache: TTLCache<TieredModalityProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredModalityProfile? {
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

        func save(_ item: TieredModalityProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredModalityProfile] {
            return inner.list()
        }
    }

    static func newCachedTieredModalityProfileStore(_ inner: MemoryTieredModalityProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredModalityProfileStore {
        return CachedTieredModalityProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered modality profiles. Empty fields match all.
    final class TieredModalityProfileQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredModalityProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredModalityProfile]) -> [TieredModalityProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredModalityProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredModalityProfiles(_ store: any TieredModalityProfileStore, query: TieredModalityProfileQuery) -> [TieredModalityProfile] {
        return query.apply(store.list())
    }
}
