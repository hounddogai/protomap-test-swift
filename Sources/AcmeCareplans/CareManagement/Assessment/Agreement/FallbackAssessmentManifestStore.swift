import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback assessment manifests by code.
    protocol FallbackAssessmentManifestStore {
        func find(_ code: String) -> FallbackAssessmentManifest?
        func save(_ item: FallbackAssessmentManifest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAssessmentManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAssessmentManifestStore: FallbackAssessmentManifestStore {
        var items: [String: FallbackAssessmentManifest]
        var order: [String]

        init(items: [String: FallbackAssessmentManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAssessmentManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAssessmentManifest) {
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

        func list() -> [FallbackAssessmentManifest] {
            var out: [FallbackAssessmentManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAssessmentManifestStore() -> any FallbackAssessmentManifestStore {
        return MemoryFallbackAssessmentManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAssessmentManifestStore: FallbackAssessmentManifestStore {
        var inner: MemoryFallbackAssessmentManifestStore
        var cache: TTLCache<FallbackAssessmentManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAssessmentManifestStore, cache: TTLCache<FallbackAssessmentManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAssessmentManifest? {
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

        func save(_ item: FallbackAssessmentManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAssessmentManifest] {
            return inner.list()
        }
    }

    static func newCachedFallbackAssessmentManifestStore(_ inner: MemoryFallbackAssessmentManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAssessmentManifestStore {
        return CachedFallbackAssessmentManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback assessment manifests. Empty fields match all.
    final class FallbackAssessmentManifestQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAssessmentManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FallbackAssessmentManifest]) -> [FallbackAssessmentManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAssessmentManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAssessmentManifests(_ store: any FallbackAssessmentManifestStore, query: FallbackAssessmentManifestQuery) -> [FallbackAssessmentManifest] {
        return query.apply(store.list())
    }
}
