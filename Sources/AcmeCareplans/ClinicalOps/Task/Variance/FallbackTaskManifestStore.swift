import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback task manifests by code.
    protocol FallbackTaskManifestStore {
        func find(_ code: String) -> FallbackTaskManifest?
        func save(_ item: FallbackTaskManifest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackTaskManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackTaskManifestStore: FallbackTaskManifestStore {
        var items: [String: FallbackTaskManifest]
        var order: [String]

        init(items: [String: FallbackTaskManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackTaskManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackTaskManifest) {
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

        func list() -> [FallbackTaskManifest] {
            var out: [FallbackTaskManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackTaskManifestStore() -> any FallbackTaskManifestStore {
        return MemoryFallbackTaskManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackTaskManifestStore: FallbackTaskManifestStore {
        var inner: MemoryFallbackTaskManifestStore
        var cache: TTLCache<FallbackTaskManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackTaskManifestStore, cache: TTLCache<FallbackTaskManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackTaskManifest? {
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

        func save(_ item: FallbackTaskManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackTaskManifest] {
            return inner.list()
        }
    }

    static func newCachedFallbackTaskManifestStore(_ inner: MemoryFallbackTaskManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackTaskManifestStore {
        return CachedFallbackTaskManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback task manifests. Empty fields match all.
    final class FallbackTaskManifestQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackTaskManifest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackTaskManifest]) -> [FallbackTaskManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackTaskManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackTaskManifests(_ store: any FallbackTaskManifestStore, query: FallbackTaskManifestQuery) -> [FallbackTaskManifest] {
        return query.apply(store.list())
    }
}
