import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal manifests by code.
    protocol GoalManifestStore {
        func find(_ code: String) -> GoalManifest?
        func save(_ item: GoalManifest)
        func remove(_ code: String) -> Bool
        func list() -> [GoalManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalManifestStore: GoalManifestStore {
        var items: [String: GoalManifest]
        var order: [String]

        init(items: [String: GoalManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalManifest) {
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

        func list() -> [GoalManifest] {
            var out: [GoalManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalManifestStore() -> any GoalManifestStore {
        return MemoryGoalManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalManifestStore: GoalManifestStore {
        var inner: MemoryGoalManifestStore
        var cache: TTLCache<GoalManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalManifestStore, cache: TTLCache<GoalManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalManifest? {
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

        func save(_ item: GoalManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalManifest] {
            return inner.list()
        }
    }

    static func newCachedGoalManifestStore(_ inner: MemoryGoalManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalManifestStore {
        return CachedGoalManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal manifests. Empty fields match all.
    final class GoalManifestQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalManifest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalManifest]) -> [GoalManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalManifests(_ store: any GoalManifestStore, query: GoalManifestQuery) -> [GoalManifest] {
        return query.apply(store.list())
    }
}
