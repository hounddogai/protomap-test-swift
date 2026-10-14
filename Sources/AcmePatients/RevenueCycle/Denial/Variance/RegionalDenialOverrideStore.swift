import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional denial overrides by code.
    protocol RegionalDenialOverrideStore {
        func find(_ code: String) -> RegionalDenialOverride?
        func save(_ item: RegionalDenialOverride)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDenialOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDenialOverrideStore: RegionalDenialOverrideStore {
        var items: [String: RegionalDenialOverride]
        var order: [String]

        init(items: [String: RegionalDenialOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDenialOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDenialOverride) {
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

        func list() -> [RegionalDenialOverride] {
            var out: [RegionalDenialOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDenialOverrideStore() -> any RegionalDenialOverrideStore {
        return MemoryRegionalDenialOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDenialOverrideStore: RegionalDenialOverrideStore {
        var inner: MemoryRegionalDenialOverrideStore
        var cache: TTLCache<RegionalDenialOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDenialOverrideStore, cache: TTLCache<RegionalDenialOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDenialOverride? {
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

        func save(_ item: RegionalDenialOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDenialOverride] {
            return inner.list()
        }
    }

    static func newCachedRegionalDenialOverrideStore(_ inner: MemoryRegionalDenialOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDenialOverrideStore {
        return CachedRegionalDenialOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional denial overrides. Empty fields match all.
    final class RegionalDenialOverrideQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDenialOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalDenialOverride]) -> [RegionalDenialOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDenialOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDenialOverrides(_ store: any RegionalDenialOverrideStore, query: RegionalDenialOverrideQuery) -> [RegionalDenialOverride] {
        return query.apply(store.list())
    }
}
