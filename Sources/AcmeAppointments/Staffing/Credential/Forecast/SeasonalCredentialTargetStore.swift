import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal credential targets by code.
    protocol SeasonalCredentialTargetStore {
        func find(_ code: String) -> SeasonalCredentialTarget?
        func save(_ item: SeasonalCredentialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCredentialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCredentialTargetStore: SeasonalCredentialTargetStore {
        var items: [String: SeasonalCredentialTarget]
        var order: [String]

        init(items: [String: SeasonalCredentialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCredentialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCredentialTarget) {
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

        func list() -> [SeasonalCredentialTarget] {
            var out: [SeasonalCredentialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCredentialTargetStore() -> any SeasonalCredentialTargetStore {
        return MemorySeasonalCredentialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCredentialTargetStore: SeasonalCredentialTargetStore {
        var inner: MemorySeasonalCredentialTargetStore
        var cache: TTLCache<SeasonalCredentialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCredentialTargetStore, cache: TTLCache<SeasonalCredentialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCredentialTarget? {
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

        func save(_ item: SeasonalCredentialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCredentialTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCredentialTargetStore(_ inner: MemorySeasonalCredentialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCredentialTargetStore {
        return CachedSeasonalCredentialTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal credential targets. Empty fields match all.
    final class SeasonalCredentialTargetQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCredentialTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCredentialTarget]) -> [SeasonalCredentialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCredentialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCredentialTargets(_ store: any SeasonalCredentialTargetStore, query: SeasonalCredentialTargetQuery) -> [SeasonalCredentialTarget] {
        return query.apply(store.list())
    }
}
