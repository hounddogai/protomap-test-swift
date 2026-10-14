import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending slot manifests by code.
    protocol PendingSlotManifestStore {
        func find(_ code: String) -> PendingSlotManifest?
        func save(_ item: PendingSlotManifest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingSlotManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingSlotManifestStore: PendingSlotManifestStore {
        var items: [String: PendingSlotManifest]
        var order: [String]

        init(items: [String: PendingSlotManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingSlotManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingSlotManifest) {
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

        func list() -> [PendingSlotManifest] {
            var out: [PendingSlotManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingSlotManifestStore() -> any PendingSlotManifestStore {
        return MemoryPendingSlotManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingSlotManifestStore: PendingSlotManifestStore {
        var inner: MemoryPendingSlotManifestStore
        var cache: TTLCache<PendingSlotManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingSlotManifestStore, cache: TTLCache<PendingSlotManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingSlotManifest? {
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

        func save(_ item: PendingSlotManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingSlotManifest] {
            return inner.list()
        }
    }

    static func newCachedPendingSlotManifestStore(_ inner: MemoryPendingSlotManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingSlotManifestStore {
        return CachedPendingSlotManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending slot manifests. Empty fields match all.
    final class PendingSlotManifestQuery {
        var unit: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRetries: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingSlotManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingSlotManifest]) -> [PendingSlotManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingSlotManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingSlotManifests(_ store: any PendingSlotManifestStore, query: PendingSlotManifestQuery) -> [PendingSlotManifest] {
        return query.apply(store.list())
    }
}
