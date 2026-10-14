import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy credential manifests by code.
    protocol LegacyCredentialManifestStore {
        func find(_ code: String) -> LegacyCredentialManifest?
        func save(_ item: LegacyCredentialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCredentialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCredentialManifestStore: LegacyCredentialManifestStore {
        var items: [String: LegacyCredentialManifest]
        var order: [String]

        init(items: [String: LegacyCredentialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCredentialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCredentialManifest) {
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

        func list() -> [LegacyCredentialManifest] {
            var out: [LegacyCredentialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCredentialManifestStore() -> any LegacyCredentialManifestStore {
        return MemoryLegacyCredentialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCredentialManifestStore: LegacyCredentialManifestStore {
        var inner: MemoryLegacyCredentialManifestStore
        var cache: TTLCache<LegacyCredentialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCredentialManifestStore, cache: TTLCache<LegacyCredentialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCredentialManifest? {
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

        func save(_ item: LegacyCredentialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCredentialManifest] {
            return inner.list()
        }
    }

    static func newCachedLegacyCredentialManifestStore(_ inner: MemoryLegacyCredentialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCredentialManifestStore {
        return CachedLegacyCredentialManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy credential manifests. Empty fields match all.
    final class LegacyCredentialManifestQuery {
        var region: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCredentialManifest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCredentialManifest]) -> [LegacyCredentialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCredentialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCredentialManifests(_ store: any LegacyCredentialManifestStore, query: LegacyCredentialManifestQuery) -> [LegacyCredentialManifest] {
        return query.apply(store.list())
    }
}
