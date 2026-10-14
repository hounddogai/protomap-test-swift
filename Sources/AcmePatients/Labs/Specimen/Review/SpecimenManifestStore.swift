import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen manifests by code.
    protocol SpecimenManifestStore {
        func find(_ code: String) -> SpecimenManifest?
        func save(_ item: SpecimenManifest)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenManifestStore: SpecimenManifestStore {
        var items: [String: SpecimenManifest]
        var order: [String]

        init(items: [String: SpecimenManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenManifest) {
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

        func list() -> [SpecimenManifest] {
            var out: [SpecimenManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenManifestStore() -> any SpecimenManifestStore {
        return MemorySpecimenManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenManifestStore: SpecimenManifestStore {
        var inner: MemorySpecimenManifestStore
        var cache: TTLCache<SpecimenManifest>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenManifestStore, cache: TTLCache<SpecimenManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenManifest? {
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

        func save(_ item: SpecimenManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenManifest] {
            return inner.list()
        }
    }

    static func newCachedSpecimenManifestStore(_ inner: MemorySpecimenManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenManifestStore {
        return CachedSpecimenManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen manifests. Empty fields match all.
    final class SpecimenManifestQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenManifest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenManifest]) -> [SpecimenManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenManifests(_ store: any SpecimenManifestStore, query: SpecimenManifestQuery) -> [SpecimenManifest] {
        return query.apply(store.list())
    }
}
