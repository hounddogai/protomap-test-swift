import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling witness manifests by code.
    protocol RollingWitnessManifestStore {
        func find(_ code: String) -> RollingWitnessManifest?
        func save(_ item: RollingWitnessManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingWitnessManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingWitnessManifestStore: RollingWitnessManifestStore {
        var items: [String: RollingWitnessManifest]
        var order: [String]

        init(items: [String: RollingWitnessManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingWitnessManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingWitnessManifest) {
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

        func list() -> [RollingWitnessManifest] {
            var out: [RollingWitnessManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingWitnessManifestStore() -> any RollingWitnessManifestStore {
        return MemoryRollingWitnessManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingWitnessManifestStore: RollingWitnessManifestStore {
        var inner: MemoryRollingWitnessManifestStore
        var cache: TTLCache<RollingWitnessManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingWitnessManifestStore, cache: TTLCache<RollingWitnessManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingWitnessManifest? {
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

        func save(_ item: RollingWitnessManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingWitnessManifest] {
            return inner.list()
        }
    }

    static func newCachedRollingWitnessManifestStore(_ inner: MemoryRollingWitnessManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingWitnessManifestStore {
        return CachedRollingWitnessManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling witness manifests. Empty fields match all.
    final class RollingWitnessManifestQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingWitnessManifest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingWitnessManifest]) -> [RollingWitnessManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingWitnessManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingWitnessManifests(_ store: any RollingWitnessManifestStore, query: RollingWitnessManifestQuery) -> [RollingWitnessManifest] {
        return query.apply(store.list())
    }
}
