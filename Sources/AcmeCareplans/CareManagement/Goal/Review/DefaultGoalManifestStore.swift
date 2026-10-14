import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default goal manifests by code.
    protocol DefaultGoalManifestStore {
        func find(_ code: String) -> DefaultGoalManifest?
        func save(_ item: DefaultGoalManifest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultGoalManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultGoalManifestStore: DefaultGoalManifestStore {
        var items: [String: DefaultGoalManifest]
        var order: [String]

        init(items: [String: DefaultGoalManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultGoalManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultGoalManifest) {
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

        func list() -> [DefaultGoalManifest] {
            var out: [DefaultGoalManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultGoalManifestStore() -> any DefaultGoalManifestStore {
        return MemoryDefaultGoalManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultGoalManifestStore: DefaultGoalManifestStore {
        var inner: MemoryDefaultGoalManifestStore
        var cache: TTLCache<DefaultGoalManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultGoalManifestStore, cache: TTLCache<DefaultGoalManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultGoalManifest? {
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

        func save(_ item: DefaultGoalManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultGoalManifest] {
            return inner.list()
        }
    }

    static func newCachedDefaultGoalManifestStore(_ inner: MemoryDefaultGoalManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultGoalManifestStore {
        return CachedDefaultGoalManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default goal manifests. Empty fields match all.
    final class DefaultGoalManifestQuery {
        var country: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRate: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultGoalManifest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultGoalManifest]) -> [DefaultGoalManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultGoalManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultGoalManifests(_ store: any DefaultGoalManifestStore, query: DefaultGoalManifestQuery) -> [DefaultGoalManifest] {
        return query.apply(store.list())
    }
}
