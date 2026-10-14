import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal care protocol targets by code.
    protocol SeasonalCareProtocolTargetStore {
        func find(_ code: String) -> SeasonalCareProtocolTarget?
        func save(_ item: SeasonalCareProtocolTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareProtocolTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareProtocolTargetStore: SeasonalCareProtocolTargetStore {
        var items: [String: SeasonalCareProtocolTarget]
        var order: [String]

        init(items: [String: SeasonalCareProtocolTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareProtocolTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareProtocolTarget) {
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

        func list() -> [SeasonalCareProtocolTarget] {
            var out: [SeasonalCareProtocolTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareProtocolTargetStore() -> any SeasonalCareProtocolTargetStore {
        return MemorySeasonalCareProtocolTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareProtocolTargetStore: SeasonalCareProtocolTargetStore {
        var inner: MemorySeasonalCareProtocolTargetStore
        var cache: TTLCache<SeasonalCareProtocolTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareProtocolTargetStore, cache: TTLCache<SeasonalCareProtocolTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareProtocolTarget? {
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

        func save(_ item: SeasonalCareProtocolTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareProtocolTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareProtocolTargetStore(_ inner: MemorySeasonalCareProtocolTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareProtocolTargetStore {
        return CachedSeasonalCareProtocolTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care protocol targets. Empty fields match all.
    final class SeasonalCareProtocolTargetQuery {
        var region: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minWeight: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareProtocolTarget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCareProtocolTarget]) -> [SeasonalCareProtocolTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareProtocolTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareProtocolTargets(_ store: any SeasonalCareProtocolTargetStore, query: SeasonalCareProtocolTargetQuery) -> [SeasonalCareProtocolTarget] {
        return query.apply(store.list())
    }
}
