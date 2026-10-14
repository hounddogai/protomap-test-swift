import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal substitution targets by code.
    protocol SeasonalSubstitutionTargetStore {
        func find(_ code: String) -> SeasonalSubstitutionTarget?
        func save(_ item: SeasonalSubstitutionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSubstitutionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSubstitutionTargetStore: SeasonalSubstitutionTargetStore {
        var items: [String: SeasonalSubstitutionTarget]
        var order: [String]

        init(items: [String: SeasonalSubstitutionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSubstitutionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSubstitutionTarget) {
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

        func list() -> [SeasonalSubstitutionTarget] {
            var out: [SeasonalSubstitutionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSubstitutionTargetStore() -> any SeasonalSubstitutionTargetStore {
        return MemorySeasonalSubstitutionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSubstitutionTargetStore: SeasonalSubstitutionTargetStore {
        var inner: MemorySeasonalSubstitutionTargetStore
        var cache: TTLCache<SeasonalSubstitutionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSubstitutionTargetStore, cache: TTLCache<SeasonalSubstitutionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSubstitutionTarget? {
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

        func save(_ item: SeasonalSubstitutionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSubstitutionTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSubstitutionTargetStore(_ inner: MemorySeasonalSubstitutionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSubstitutionTargetStore {
        return CachedSeasonalSubstitutionTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal substitution targets. Empty fields match all.
    final class SeasonalSubstitutionTargetQuery {
        var facility: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRefills: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSubstitutionTarget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalSubstitutionTarget]) -> [SeasonalSubstitutionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSubstitutionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSubstitutionTargets(_ store: any SeasonalSubstitutionTargetStore, query: SeasonalSubstitutionTargetQuery) -> [SeasonalSubstitutionTarget] {
        return query.apply(store.list())
    }
}
