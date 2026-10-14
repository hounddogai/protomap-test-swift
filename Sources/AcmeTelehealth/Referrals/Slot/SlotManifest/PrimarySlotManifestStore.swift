import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary slot manifests by code.
    protocol PrimarySlotManifestStore {
        func find(_ code: String) -> PrimarySlotManifest?
        func save(_ item: PrimarySlotManifest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySlotManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySlotManifestStore: PrimarySlotManifestStore {
        var items: [String: PrimarySlotManifest]
        var order: [String]

        init(items: [String: PrimarySlotManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySlotManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySlotManifest) {
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

        func list() -> [PrimarySlotManifest] {
            var out: [PrimarySlotManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySlotManifestStore() -> any PrimarySlotManifestStore {
        return MemoryPrimarySlotManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySlotManifestStore: PrimarySlotManifestStore {
        var inner: MemoryPrimarySlotManifestStore
        var cache: TTLCache<PrimarySlotManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySlotManifestStore, cache: TTLCache<PrimarySlotManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySlotManifest? {
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

        func save(_ item: PrimarySlotManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySlotManifest] {
            return inner.list()
        }
    }

    static func newCachedPrimarySlotManifestStore(_ inner: MemoryPrimarySlotManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySlotManifestStore {
        return CachedPrimarySlotManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary slot manifests. Empty fields match all.
    final class PrimarySlotManifestQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySlotManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySlotManifest]) -> [PrimarySlotManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySlotManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySlotManifests(_ store: any PrimarySlotManifestStore, query: PrimarySlotManifestQuery) -> [PrimarySlotManifest] {
        return query.apply(store.list())
    }
}
