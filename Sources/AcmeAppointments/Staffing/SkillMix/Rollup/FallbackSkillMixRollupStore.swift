import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback skill mix rollups by code.
    protocol FallbackSkillMixRollupStore {
        func find(_ code: String) -> FallbackSkillMixRollup?
        func save(_ item: FallbackSkillMixRollup)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSkillMixRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSkillMixRollupStore: FallbackSkillMixRollupStore {
        var items: [String: FallbackSkillMixRollup]
        var order: [String]

        init(items: [String: FallbackSkillMixRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSkillMixRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSkillMixRollup) {
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

        func list() -> [FallbackSkillMixRollup] {
            var out: [FallbackSkillMixRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSkillMixRollupStore() -> any FallbackSkillMixRollupStore {
        return MemoryFallbackSkillMixRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSkillMixRollupStore: FallbackSkillMixRollupStore {
        var inner: MemoryFallbackSkillMixRollupStore
        var cache: TTLCache<FallbackSkillMixRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSkillMixRollupStore, cache: TTLCache<FallbackSkillMixRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSkillMixRollup? {
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

        func save(_ item: FallbackSkillMixRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSkillMixRollup] {
            return inner.list()
        }
    }

    static func newCachedFallbackSkillMixRollupStore(_ inner: MemoryFallbackSkillMixRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSkillMixRollupStore {
        return CachedFallbackSkillMixRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback skill mix rollups. Empty fields match all.
    final class FallbackSkillMixRollupQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSkillMixRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [FallbackSkillMixRollup]) -> [FallbackSkillMixRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSkillMixRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSkillMixRollups(_ store: any FallbackSkillMixRollupStore, query: FallbackSkillMixRollupQuery) -> [FallbackSkillMixRollup] {
        return query.apply(store.list())
    }
}
