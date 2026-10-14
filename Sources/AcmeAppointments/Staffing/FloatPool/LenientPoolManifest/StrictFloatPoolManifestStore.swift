import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict float pool manifests by code.
    protocol StrictFloatPoolManifestStore {
        func find(_ code: String) -> StrictFloatPoolManifest?
        func save(_ item: StrictFloatPoolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictFloatPoolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictFloatPoolManifestStore: StrictFloatPoolManifestStore {
        var items: [String: StrictFloatPoolManifest]
        var order: [String]

        init(items: [String: StrictFloatPoolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictFloatPoolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictFloatPoolManifest) {
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

        func list() -> [StrictFloatPoolManifest] {
            var out: [StrictFloatPoolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictFloatPoolManifestStore() -> any StrictFloatPoolManifestStore {
        return MemoryStrictFloatPoolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictFloatPoolManifestStore: StrictFloatPoolManifestStore {
        var inner: MemoryStrictFloatPoolManifestStore
        var cache: TTLCache<StrictFloatPoolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictFloatPoolManifestStore, cache: TTLCache<StrictFloatPoolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictFloatPoolManifest? {
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

        func save(_ item: StrictFloatPoolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictFloatPoolManifest] {
            return inner.list()
        }
    }

    static func newCachedStrictFloatPoolManifestStore(_ inner: MemoryStrictFloatPoolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictFloatPoolManifestStore {
        return CachedStrictFloatPoolManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict float pool manifests. Empty fields match all.
    final class StrictFloatPoolManifestQuery {
        var unit: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictFloatPoolManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictFloatPoolManifest]) -> [StrictFloatPoolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictFloatPoolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictFloatPoolManifests(_ store: any StrictFloatPoolManifestStore, query: StrictFloatPoolManifestQuery) -> [StrictFloatPoolManifest] {
        return query.apply(store.list())
    }
}
