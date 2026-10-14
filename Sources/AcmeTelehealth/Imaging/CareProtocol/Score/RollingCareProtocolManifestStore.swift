import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling care protocol manifests by code.
    protocol RollingCareProtocolManifestStore {
        func find(_ code: String) -> RollingCareProtocolManifest?
        func save(_ item: RollingCareProtocolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCareProtocolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCareProtocolManifestStore: RollingCareProtocolManifestStore {
        var items: [String: RollingCareProtocolManifest]
        var order: [String]

        init(items: [String: RollingCareProtocolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCareProtocolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCareProtocolManifest) {
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

        func list() -> [RollingCareProtocolManifest] {
            var out: [RollingCareProtocolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCareProtocolManifestStore() -> any RollingCareProtocolManifestStore {
        return MemoryRollingCareProtocolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCareProtocolManifestStore: RollingCareProtocolManifestStore {
        var inner: MemoryRollingCareProtocolManifestStore
        var cache: TTLCache<RollingCareProtocolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCareProtocolManifestStore, cache: TTLCache<RollingCareProtocolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCareProtocolManifest? {
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

        func save(_ item: RollingCareProtocolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCareProtocolManifest] {
            return inner.list()
        }
    }

    static func newCachedRollingCareProtocolManifestStore(_ inner: MemoryRollingCareProtocolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCareProtocolManifestStore {
        return CachedRollingCareProtocolManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling care protocol manifests. Empty fields match all.
    final class RollingCareProtocolManifestQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCareProtocolManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCareProtocolManifest]) -> [RollingCareProtocolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCareProtocolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCareProtocolManifests(_ store: any RollingCareProtocolManifestStore, query: RollingCareProtocolManifestQuery) -> [RollingCareProtocolManifest] {
        return query.apply(store.list())
    }
}
