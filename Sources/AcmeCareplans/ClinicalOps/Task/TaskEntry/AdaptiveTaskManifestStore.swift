import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive task manifests by code.
    protocol AdaptiveTaskManifestStore {
        func find(_ code: String) -> AdaptiveTaskManifest?
        func save(_ item: AdaptiveTaskManifest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveTaskManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveTaskManifestStore: AdaptiveTaskManifestStore {
        var items: [String: AdaptiveTaskManifest]
        var order: [String]

        init(items: [String: AdaptiveTaskManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveTaskManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveTaskManifest) {
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

        func list() -> [AdaptiveTaskManifest] {
            var out: [AdaptiveTaskManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveTaskManifestStore() -> any AdaptiveTaskManifestStore {
        return MemoryAdaptiveTaskManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveTaskManifestStore: AdaptiveTaskManifestStore {
        var inner: MemoryAdaptiveTaskManifestStore
        var cache: TTLCache<AdaptiveTaskManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveTaskManifestStore, cache: TTLCache<AdaptiveTaskManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveTaskManifest? {
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

        func save(_ item: AdaptiveTaskManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveTaskManifest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveTaskManifestStore(_ inner: MemoryAdaptiveTaskManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveTaskManifestStore {
        return CachedAdaptiveTaskManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive task manifests. Empty fields match all.
    final class AdaptiveTaskManifestQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveTaskManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveTaskManifest]) -> [AdaptiveTaskManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveTaskManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveTaskManifests(_ store: any AdaptiveTaskManifestStore, query: AdaptiveTaskManifestQuery) -> [AdaptiveTaskManifest] {
        return query.apply(store.list())
    }
}
