import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global float pool manifests by code.
    protocol GlobalFloatPoolManifestStore {
        func find(_ code: String) -> GlobalFloatPoolManifest?
        func save(_ item: GlobalFloatPoolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalFloatPoolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalFloatPoolManifestStore: GlobalFloatPoolManifestStore {
        var items: [String: GlobalFloatPoolManifest]
        var order: [String]

        init(items: [String: GlobalFloatPoolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalFloatPoolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalFloatPoolManifest) {
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

        func list() -> [GlobalFloatPoolManifest] {
            var out: [GlobalFloatPoolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalFloatPoolManifestStore() -> any GlobalFloatPoolManifestStore {
        return MemoryGlobalFloatPoolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalFloatPoolManifestStore: GlobalFloatPoolManifestStore {
        var inner: MemoryGlobalFloatPoolManifestStore
        var cache: TTLCache<GlobalFloatPoolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalFloatPoolManifestStore, cache: TTLCache<GlobalFloatPoolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalFloatPoolManifest? {
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

        func save(_ item: GlobalFloatPoolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalFloatPoolManifest] {
            return inner.list()
        }
    }

    static func newCachedGlobalFloatPoolManifestStore(_ inner: MemoryGlobalFloatPoolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalFloatPoolManifestStore {
        return CachedGlobalFloatPoolManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global float pool manifests. Empty fields match all.
    final class GlobalFloatPoolManifestQuery {
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

        func matches(_ item: GlobalFloatPoolManifest) -> Bool {
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

        func apply(_ items: [GlobalFloatPoolManifest]) -> [GlobalFloatPoolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalFloatPoolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalFloatPoolManifests(_ store: any GlobalFloatPoolManifestStore, query: GlobalFloatPoolManifestQuery) -> [GlobalFloatPoolManifest] {
        return query.apply(store.list())
    }
}
