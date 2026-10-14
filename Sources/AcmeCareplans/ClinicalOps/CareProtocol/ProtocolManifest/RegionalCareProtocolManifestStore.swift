import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional care protocol manifests by code.
    protocol RegionalCareProtocolManifestStore {
        func find(_ code: String) -> RegionalCareProtocolManifest?
        func save(_ item: RegionalCareProtocolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCareProtocolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCareProtocolManifestStore: RegionalCareProtocolManifestStore {
        var items: [String: RegionalCareProtocolManifest]
        var order: [String]

        init(items: [String: RegionalCareProtocolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCareProtocolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCareProtocolManifest) {
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

        func list() -> [RegionalCareProtocolManifest] {
            var out: [RegionalCareProtocolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCareProtocolManifestStore() -> any RegionalCareProtocolManifestStore {
        return MemoryRegionalCareProtocolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCareProtocolManifestStore: RegionalCareProtocolManifestStore {
        var inner: MemoryRegionalCareProtocolManifestStore
        var cache: TTLCache<RegionalCareProtocolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCareProtocolManifestStore, cache: TTLCache<RegionalCareProtocolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCareProtocolManifest? {
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

        func save(_ item: RegionalCareProtocolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCareProtocolManifest] {
            return inner.list()
        }
    }

    static func newCachedRegionalCareProtocolManifestStore(_ inner: MemoryRegionalCareProtocolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCareProtocolManifestStore {
        return CachedRegionalCareProtocolManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional care protocol manifests. Empty fields match all.
    final class RegionalCareProtocolManifestQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCareProtocolManifest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [RegionalCareProtocolManifest]) -> [RegionalCareProtocolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCareProtocolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCareProtocolManifests(_ store: any RegionalCareProtocolManifestStore, query: RegionalCareProtocolManifestQuery) -> [RegionalCareProtocolManifest] {
        return query.apply(store.list())
    }
}
