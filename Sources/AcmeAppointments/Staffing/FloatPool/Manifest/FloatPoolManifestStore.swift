import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool manifests by code.
    protocol FloatPoolManifestStore {
        func find(_ code: String) -> FloatPoolManifest?
        func save(_ item: FloatPoolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolManifestStore: FloatPoolManifestStore {
        var items: [String: FloatPoolManifest]
        var order: [String]

        init(items: [String: FloatPoolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolManifest) {
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

        func list() -> [FloatPoolManifest] {
            var out: [FloatPoolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolManifestStore() -> any FloatPoolManifestStore {
        return MemoryFloatPoolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolManifestStore: FloatPoolManifestStore {
        var inner: MemoryFloatPoolManifestStore
        var cache: TTLCache<FloatPoolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolManifestStore, cache: TTLCache<FloatPoolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolManifest? {
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

        func save(_ item: FloatPoolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolManifest] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolManifestStore(_ inner: MemoryFloatPoolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolManifestStore {
        return CachedFloatPoolManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool manifests. Empty fields match all.
    final class FloatPoolManifestQuery {
        var facility: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minBudget: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolManifest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolManifest]) -> [FloatPoolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolManifests(_ store: any FloatPoolManifestStore, query: FloatPoolManifestQuery) -> [FloatPoolManifest] {
        return query.apply(store.list())
    }
}
