import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending denial manifests by code.
    protocol PendingDenialManifestStore {
        func find(_ code: String) -> PendingDenialManifest?
        func save(_ item: PendingDenialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDenialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDenialManifestStore: PendingDenialManifestStore {
        var items: [String: PendingDenialManifest]
        var order: [String]

        init(items: [String: PendingDenialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDenialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDenialManifest) {
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

        func list() -> [PendingDenialManifest] {
            var out: [PendingDenialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDenialManifestStore() -> any PendingDenialManifestStore {
        return MemoryPendingDenialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDenialManifestStore: PendingDenialManifestStore {
        var inner: MemoryPendingDenialManifestStore
        var cache: TTLCache<PendingDenialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDenialManifestStore, cache: TTLCache<PendingDenialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDenialManifest? {
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

        func save(_ item: PendingDenialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDenialManifest] {
            return inner.list()
        }
    }

    static func newCachedPendingDenialManifestStore(_ inner: MemoryPendingDenialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDenialManifestStore {
        return CachedPendingDenialManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending denial manifests. Empty fields match all.
    final class PendingDenialManifestQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDenialManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDenialManifest]) -> [PendingDenialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDenialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDenialManifests(_ store: any PendingDenialManifestStore, query: PendingDenialManifestQuery) -> [PendingDenialManifest] {
        return query.apply(store.list())
    }
}
