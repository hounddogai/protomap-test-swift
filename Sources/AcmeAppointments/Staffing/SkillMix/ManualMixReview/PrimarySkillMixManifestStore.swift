import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary skill mix manifests by code.
    protocol PrimarySkillMixManifestStore {
        func find(_ code: String) -> PrimarySkillMixManifest?
        func save(_ item: PrimarySkillMixManifest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySkillMixManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySkillMixManifestStore: PrimarySkillMixManifestStore {
        var items: [String: PrimarySkillMixManifest]
        var order: [String]

        init(items: [String: PrimarySkillMixManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySkillMixManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySkillMixManifest) {
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

        func list() -> [PrimarySkillMixManifest] {
            var out: [PrimarySkillMixManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySkillMixManifestStore() -> any PrimarySkillMixManifestStore {
        return MemoryPrimarySkillMixManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySkillMixManifestStore: PrimarySkillMixManifestStore {
        var inner: MemoryPrimarySkillMixManifestStore
        var cache: TTLCache<PrimarySkillMixManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySkillMixManifestStore, cache: TTLCache<PrimarySkillMixManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySkillMixManifest? {
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

        func save(_ item: PrimarySkillMixManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySkillMixManifest] {
            return inner.list()
        }
    }

    static func newCachedPrimarySkillMixManifestStore(_ inner: MemoryPrimarySkillMixManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySkillMixManifestStore {
        return CachedPrimarySkillMixManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary skill mix manifests. Empty fields match all.
    final class PrimarySkillMixManifestQuery {
        var unit: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minWeight: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySkillMixManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PrimarySkillMixManifest]) -> [PrimarySkillMixManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySkillMixManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySkillMixManifests(_ store: any PrimarySkillMixManifestStore, query: PrimarySkillMixManifestQuery) -> [PrimarySkillMixManifest] {
        return query.apply(store.list())
    }
}
