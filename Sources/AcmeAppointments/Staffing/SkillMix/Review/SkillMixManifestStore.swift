import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix manifests by code.
    protocol SkillMixManifestStore {
        func find(_ code: String) -> SkillMixManifest?
        func save(_ item: SkillMixManifest)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixManifestStore: SkillMixManifestStore {
        var items: [String: SkillMixManifest]
        var order: [String]

        init(items: [String: SkillMixManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixManifest) {
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

        func list() -> [SkillMixManifest] {
            var out: [SkillMixManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixManifestStore() -> any SkillMixManifestStore {
        return MemorySkillMixManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixManifestStore: SkillMixManifestStore {
        var inner: MemorySkillMixManifestStore
        var cache: TTLCache<SkillMixManifest>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixManifestStore, cache: TTLCache<SkillMixManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixManifest? {
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

        func save(_ item: SkillMixManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixManifest] {
            return inner.list()
        }
    }

    static func newCachedSkillMixManifestStore(_ inner: MemorySkillMixManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixManifestStore {
        return CachedSkillMixManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix manifests. Empty fields match all.
    final class SkillMixManifestQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixManifest]) -> [SkillMixManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixManifests(_ store: any SkillMixManifestStore, query: SkillMixManifestQuery) -> [SkillMixManifest] {
        return query.apply(store.list())
    }
}
