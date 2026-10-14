import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default rounding manifests by code.
    protocol DefaultRoundingManifestStore {
        func find(_ code: String) -> DefaultRoundingManifest?
        func save(_ item: DefaultRoundingManifest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRoundingManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRoundingManifestStore: DefaultRoundingManifestStore {
        var items: [String: DefaultRoundingManifest]
        var order: [String]

        init(items: [String: DefaultRoundingManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRoundingManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRoundingManifest) {
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

        func list() -> [DefaultRoundingManifest] {
            var out: [DefaultRoundingManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRoundingManifestStore() -> any DefaultRoundingManifestStore {
        return MemoryDefaultRoundingManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRoundingManifestStore: DefaultRoundingManifestStore {
        var inner: MemoryDefaultRoundingManifestStore
        var cache: TTLCache<DefaultRoundingManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRoundingManifestStore, cache: TTLCache<DefaultRoundingManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRoundingManifest? {
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

        func save(_ item: DefaultRoundingManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRoundingManifest] {
            return inner.list()
        }
    }

    static func newCachedDefaultRoundingManifestStore(_ inner: MemoryDefaultRoundingManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRoundingManifestStore {
        return CachedDefaultRoundingManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default rounding manifests. Empty fields match all.
    final class DefaultRoundingManifestQuery {
        var source: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRoundingManifest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRoundingManifest]) -> [DefaultRoundingManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRoundingManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRoundingManifests(_ store: any DefaultRoundingManifestStore, query: DefaultRoundingManifestQuery) -> [DefaultRoundingManifest] {
        return query.apply(store.list())
    }
}
