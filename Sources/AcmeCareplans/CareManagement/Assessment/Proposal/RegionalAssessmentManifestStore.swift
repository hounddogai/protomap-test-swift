import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional assessment manifests by code.
    protocol RegionalAssessmentManifestStore {
        func find(_ code: String) -> RegionalAssessmentManifest?
        func save(_ item: RegionalAssessmentManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAssessmentManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAssessmentManifestStore: RegionalAssessmentManifestStore {
        var items: [String: RegionalAssessmentManifest]
        var order: [String]

        init(items: [String: RegionalAssessmentManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAssessmentManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAssessmentManifest) {
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

        func list() -> [RegionalAssessmentManifest] {
            var out: [RegionalAssessmentManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAssessmentManifestStore() -> any RegionalAssessmentManifestStore {
        return MemoryRegionalAssessmentManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAssessmentManifestStore: RegionalAssessmentManifestStore {
        var inner: MemoryRegionalAssessmentManifestStore
        var cache: TTLCache<RegionalAssessmentManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAssessmentManifestStore, cache: TTLCache<RegionalAssessmentManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAssessmentManifest? {
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

        func save(_ item: RegionalAssessmentManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAssessmentManifest] {
            return inner.list()
        }
    }

    static func newCachedRegionalAssessmentManifestStore(_ inner: MemoryRegionalAssessmentManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAssessmentManifestStore {
        return CachedRegionalAssessmentManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional assessment manifests. Empty fields match all.
    final class RegionalAssessmentManifestQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAssessmentManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAssessmentManifest]) -> [RegionalAssessmentManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAssessmentManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAssessmentManifests(_ store: any RegionalAssessmentManifestStore, query: RegionalAssessmentManifestQuery) -> [RegionalAssessmentManifest] {
        return query.apply(store.list())
    }
}
