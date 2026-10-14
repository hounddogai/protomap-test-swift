import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered substitution profiles by code.
    protocol TieredSubstitutionProfileStore {
        func find(_ code: String) -> TieredSubstitutionProfile?
        func save(_ item: TieredSubstitutionProfile)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSubstitutionProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSubstitutionProfileStore: TieredSubstitutionProfileStore {
        var items: [String: TieredSubstitutionProfile]
        var order: [String]

        init(items: [String: TieredSubstitutionProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSubstitutionProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSubstitutionProfile) {
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

        func list() -> [TieredSubstitutionProfile] {
            var out: [TieredSubstitutionProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSubstitutionProfileStore() -> any TieredSubstitutionProfileStore {
        return MemoryTieredSubstitutionProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSubstitutionProfileStore: TieredSubstitutionProfileStore {
        var inner: MemoryTieredSubstitutionProfileStore
        var cache: TTLCache<TieredSubstitutionProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSubstitutionProfileStore, cache: TTLCache<TieredSubstitutionProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSubstitutionProfile? {
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

        func save(_ item: TieredSubstitutionProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSubstitutionProfile] {
            return inner.list()
        }
    }

    static func newCachedTieredSubstitutionProfileStore(_ inner: MemoryTieredSubstitutionProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSubstitutionProfileStore {
        return CachedTieredSubstitutionProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered substitution profiles. Empty fields match all.
    final class TieredSubstitutionProfileQuery {
        var source: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSubstitutionProfile) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredSubstitutionProfile]) -> [TieredSubstitutionProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSubstitutionProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSubstitutionProfiles(_ store: any TieredSubstitutionProfileStore, query: TieredSubstitutionProfileQuery) -> [TieredSubstitutionProfile] {
        return query.apply(store.list())
    }
}
