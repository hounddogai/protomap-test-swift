import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling shift manifests by code.
    protocol RollingShiftManifestStore {
        func find(_ code: String) -> RollingShiftManifest?
        func save(_ item: RollingShiftManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingShiftManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingShiftManifestStore: RollingShiftManifestStore {
        var items: [String: RollingShiftManifest]
        var order: [String]

        init(items: [String: RollingShiftManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingShiftManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingShiftManifest) {
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

        func list() -> [RollingShiftManifest] {
            var out: [RollingShiftManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingShiftManifestStore() -> any RollingShiftManifestStore {
        return MemoryRollingShiftManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingShiftManifestStore: RollingShiftManifestStore {
        var inner: MemoryRollingShiftManifestStore
        var cache: TTLCache<RollingShiftManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingShiftManifestStore, cache: TTLCache<RollingShiftManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingShiftManifest? {
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

        func save(_ item: RollingShiftManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingShiftManifest] {
            return inner.list()
        }
    }

    static func newCachedRollingShiftManifestStore(_ inner: MemoryRollingShiftManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingShiftManifestStore {
        return CachedRollingShiftManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling shift manifests. Empty fields match all.
    final class RollingShiftManifestQuery {
        var region: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRevision: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingShiftManifest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingShiftManifest]) -> [RollingShiftManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingShiftManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingShiftManifests(_ store: any RollingShiftManifestStore, query: RollingShiftManifestQuery) -> [RollingShiftManifest] {
        return query.apply(store.list())
    }
}
