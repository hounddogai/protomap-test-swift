import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim manifests by code.
    protocol ClaimManifestStore {
        func find(_ code: String) -> ClaimManifest?
        func save(_ item: ClaimManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimManifestStore: ClaimManifestStore {
        var items: [String: ClaimManifest]
        var order: [String]

        init(items: [String: ClaimManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimManifest) {
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

        func list() -> [ClaimManifest] {
            var out: [ClaimManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimManifestStore() -> any ClaimManifestStore {
        return MemoryClaimManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimManifestStore: ClaimManifestStore {
        var inner: MemoryClaimManifestStore
        var cache: TTLCache<ClaimManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimManifestStore, cache: TTLCache<ClaimManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimManifest? {
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

        func save(_ item: ClaimManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimManifest] {
            return inner.list()
        }
    }

    static func newCachedClaimManifestStore(_ inner: MemoryClaimManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimManifestStore {
        return CachedClaimManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim manifests. Empty fields match all.
    final class ClaimManifestQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ClaimManifest]) -> [ClaimManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimManifests(_ store: any ClaimManifestStore, query: ClaimManifestQuery) -> [ClaimManifest] {
        return query.apply(store.list())
    }
}
