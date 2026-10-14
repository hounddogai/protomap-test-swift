import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual inventory manifests by code.
    protocol ManualInventoryManifestStore {
        func find(_ code: String) -> ManualInventoryManifest?
        func save(_ item: ManualInventoryManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualInventoryManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualInventoryManifestStore: ManualInventoryManifestStore {
        var items: [String: ManualInventoryManifest]
        var order: [String]

        init(items: [String: ManualInventoryManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualInventoryManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualInventoryManifest) {
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

        func list() -> [ManualInventoryManifest] {
            var out: [ManualInventoryManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualInventoryManifestStore() -> any ManualInventoryManifestStore {
        return MemoryManualInventoryManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualInventoryManifestStore: ManualInventoryManifestStore {
        var inner: MemoryManualInventoryManifestStore
        var cache: TTLCache<ManualInventoryManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualInventoryManifestStore, cache: TTLCache<ManualInventoryManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualInventoryManifest? {
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

        func save(_ item: ManualInventoryManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualInventoryManifest] {
            return inner.list()
        }
    }

    static func newCachedManualInventoryManifestStore(_ inner: MemoryManualInventoryManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualInventoryManifestStore {
        return CachedManualInventoryManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual inventory manifests. Empty fields match all.
    final class ManualInventoryManifestQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualInventoryManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualInventoryManifest]) -> [ManualInventoryManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualInventoryManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualInventoryManifests(_ store: any ManualInventoryManifestStore, query: ManualInventoryManifestQuery) -> [ManualInventoryManifest] {
        return query.apply(store.list())
    }
}
