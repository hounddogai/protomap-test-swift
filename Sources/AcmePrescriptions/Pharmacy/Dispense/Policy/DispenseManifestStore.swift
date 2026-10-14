import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense manifests by code.
    protocol DispenseManifestStore {
        func find(_ code: String) -> DispenseManifest?
        func save(_ item: DispenseManifest)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseManifestStore: DispenseManifestStore {
        var items: [String: DispenseManifest]
        var order: [String]

        init(items: [String: DispenseManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseManifest) {
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

        func list() -> [DispenseManifest] {
            var out: [DispenseManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseManifestStore() -> any DispenseManifestStore {
        return MemoryDispenseManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseManifestStore: DispenseManifestStore {
        var inner: MemoryDispenseManifestStore
        var cache: TTLCache<DispenseManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseManifestStore, cache: TTLCache<DispenseManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseManifest? {
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

        func save(_ item: DispenseManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseManifest] {
            return inner.list()
        }
    }

    static func newCachedDispenseManifestStore(_ inner: MemoryDispenseManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseManifestStore {
        return CachedDispenseManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense manifests. Empty fields match all.
    final class DispenseManifestQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseManifest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseManifest]) -> [DispenseManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseManifests(_ store: any DispenseManifestStore, query: DispenseManifestQuery) -> [DispenseManifest] {
        return query.apply(store.list())
    }
}
