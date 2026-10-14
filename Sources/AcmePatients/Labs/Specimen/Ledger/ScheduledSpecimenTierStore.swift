import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled specimen tiers by code.
    protocol ScheduledSpecimenTierStore {
        func find(_ code: String) -> ScheduledSpecimenTier?
        func save(_ item: ScheduledSpecimenTier)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledSpecimenTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledSpecimenTierStore: ScheduledSpecimenTierStore {
        var items: [String: ScheduledSpecimenTier]
        var order: [String]

        init(items: [String: ScheduledSpecimenTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledSpecimenTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledSpecimenTier) {
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

        func list() -> [ScheduledSpecimenTier] {
            var out: [ScheduledSpecimenTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledSpecimenTierStore() -> any ScheduledSpecimenTierStore {
        return MemoryScheduledSpecimenTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledSpecimenTierStore: ScheduledSpecimenTierStore {
        var inner: MemoryScheduledSpecimenTierStore
        var cache: TTLCache<ScheduledSpecimenTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledSpecimenTierStore, cache: TTLCache<ScheduledSpecimenTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledSpecimenTier? {
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

        func save(_ item: ScheduledSpecimenTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledSpecimenTier] {
            return inner.list()
        }
    }

    static func newCachedScheduledSpecimenTierStore(_ inner: MemoryScheduledSpecimenTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledSpecimenTierStore {
        return CachedScheduledSpecimenTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled specimen tiers. Empty fields match all.
    final class ScheduledSpecimenTierQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledSpecimenTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ScheduledSpecimenTier]) -> [ScheduledSpecimenTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledSpecimenTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledSpecimenTiers(_ store: any ScheduledSpecimenTierStore, query: ScheduledSpecimenTierQuery) -> [ScheduledSpecimenTier] {
        return query.apply(store.list())
    }
}
