import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling revocation manifests by code.
    protocol RollingRevocationManifestStore {
        func find(_ code: String) -> RollingRevocationManifest?
        func save(_ item: RollingRevocationManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRevocationManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRevocationManifestStore: RollingRevocationManifestStore {
        var items: [String: RollingRevocationManifest]
        var order: [String]

        init(items: [String: RollingRevocationManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRevocationManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRevocationManifest) {
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

        func list() -> [RollingRevocationManifest] {
            var out: [RollingRevocationManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRevocationManifestStore() -> any RollingRevocationManifestStore {
        return MemoryRollingRevocationManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRevocationManifestStore: RollingRevocationManifestStore {
        var inner: MemoryRollingRevocationManifestStore
        var cache: TTLCache<RollingRevocationManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRevocationManifestStore, cache: TTLCache<RollingRevocationManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRevocationManifest? {
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

        func save(_ item: RollingRevocationManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRevocationManifest] {
            return inner.list()
        }
    }

    static func newCachedRollingRevocationManifestStore(_ inner: MemoryRollingRevocationManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRevocationManifestStore {
        return CachedRollingRevocationManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling revocation manifests. Empty fields match all.
    final class RollingRevocationManifestQuery {
        var country: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRevocationManifest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingRevocationManifest]) -> [RollingRevocationManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRevocationManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRevocationManifests(_ store: any RollingRevocationManifestStore, query: RollingRevocationManifestQuery) -> [RollingRevocationManifest] {
        return query.apply(store.list())
    }
}
