import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient isolation manifests by code.
    protocol LenientIsolationManifestStore {
        func find(_ code: String) -> LenientIsolationManifest?
        func save(_ item: LenientIsolationManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientIsolationManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientIsolationManifestStore: LenientIsolationManifestStore {
        var items: [String: LenientIsolationManifest]
        var order: [String]

        init(items: [String: LenientIsolationManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientIsolationManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientIsolationManifest) {
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

        func list() -> [LenientIsolationManifest] {
            var out: [LenientIsolationManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientIsolationManifestStore() -> any LenientIsolationManifestStore {
        return MemoryLenientIsolationManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientIsolationManifestStore: LenientIsolationManifestStore {
        var inner: MemoryLenientIsolationManifestStore
        var cache: TTLCache<LenientIsolationManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientIsolationManifestStore, cache: TTLCache<LenientIsolationManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientIsolationManifest? {
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

        func save(_ item: LenientIsolationManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientIsolationManifest] {
            return inner.list()
        }
    }

    static func newCachedLenientIsolationManifestStore(_ inner: MemoryLenientIsolationManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientIsolationManifestStore {
        return CachedLenientIsolationManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient isolation manifests. Empty fields match all.
    final class LenientIsolationManifestQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientIsolationManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientIsolationManifest]) -> [LenientIsolationManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientIsolationManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientIsolationManifests(_ store: any LenientIsolationManifestStore, query: LenientIsolationManifestQuery) -> [LenientIsolationManifest] {
        return query.apply(store.list())
    }
}
