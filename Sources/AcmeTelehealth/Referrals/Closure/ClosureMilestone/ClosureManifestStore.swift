import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure manifests by code.
    protocol ClosureManifestStore {
        func find(_ code: String) -> ClosureManifest?
        func save(_ item: ClosureManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureManifestStore: ClosureManifestStore {
        var items: [String: ClosureManifest]
        var order: [String]

        init(items: [String: ClosureManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureManifest) {
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

        func list() -> [ClosureManifest] {
            var out: [ClosureManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureManifestStore() -> any ClosureManifestStore {
        return MemoryClosureManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureManifestStore: ClosureManifestStore {
        var inner: MemoryClosureManifestStore
        var cache: TTLCache<ClosureManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureManifestStore, cache: TTLCache<ClosureManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureManifest? {
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

        func save(_ item: ClosureManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureManifest] {
            return inner.list()
        }
    }

    static func newCachedClosureManifestStore(_ inner: MemoryClosureManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureManifestStore {
        return CachedClosureManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure manifests. Empty fields match all.
    final class ClosureManifestQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureManifest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ClosureManifest]) -> [ClosureManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureManifests(_ store: any ClosureManifestStore, query: ClosureManifestQuery) -> [ClosureManifest] {
        return query.apply(store.list())
    }
}
