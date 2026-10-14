import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan overrides by code.
    protocol DischargePlanOverrideStore {
        func find(_ code: String) -> DischargePlanOverride?
        func save(_ item: DischargePlanOverride)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanOverrideStore: DischargePlanOverrideStore {
        var items: [String: DischargePlanOverride]
        var order: [String]

        init(items: [String: DischargePlanOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanOverride) {
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

        func list() -> [DischargePlanOverride] {
            var out: [DischargePlanOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanOverrideStore() -> any DischargePlanOverrideStore {
        return MemoryDischargePlanOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanOverrideStore: DischargePlanOverrideStore {
        var inner: MemoryDischargePlanOverrideStore
        var cache: TTLCache<DischargePlanOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanOverrideStore, cache: TTLCache<DischargePlanOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanOverride? {
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

        func save(_ item: DischargePlanOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanOverride] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanOverrideStore(_ inner: MemoryDischargePlanOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanOverrideStore {
        return CachedDischargePlanOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan overrides. Empty fields match all.
    final class DischargePlanOverrideQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanOverride) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanOverride]) -> [DischargePlanOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanOverrides(_ store: any DischargePlanOverrideStore, query: DischargePlanOverrideQuery) -> [DischargePlanOverride] {
        return query.apply(store.list())
    }
}
