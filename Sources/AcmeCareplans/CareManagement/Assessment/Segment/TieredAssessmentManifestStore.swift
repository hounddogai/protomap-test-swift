import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered assessment manifests by code.
    protocol TieredAssessmentManifestStore {
        func find(_ code: String) -> TieredAssessmentManifest?
        func save(_ item: TieredAssessmentManifest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAssessmentManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAssessmentManifestStore: TieredAssessmentManifestStore {
        var items: [String: TieredAssessmentManifest]
        var order: [String]

        init(items: [String: TieredAssessmentManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAssessmentManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAssessmentManifest) {
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

        func list() -> [TieredAssessmentManifest] {
            var out: [TieredAssessmentManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAssessmentManifestStore() -> any TieredAssessmentManifestStore {
        return MemoryTieredAssessmentManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAssessmentManifestStore: TieredAssessmentManifestStore {
        var inner: MemoryTieredAssessmentManifestStore
        var cache: TTLCache<TieredAssessmentManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAssessmentManifestStore, cache: TTLCache<TieredAssessmentManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAssessmentManifest? {
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

        func save(_ item: TieredAssessmentManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAssessmentManifest] {
            return inner.list()
        }
    }

    static func newCachedTieredAssessmentManifestStore(_ inner: MemoryTieredAssessmentManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAssessmentManifestStore {
        return CachedTieredAssessmentManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered assessment manifests. Empty fields match all.
    final class TieredAssessmentManifestQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredAssessmentManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredAssessmentManifest]) -> [TieredAssessmentManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAssessmentManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAssessmentManifests(_ store: any TieredAssessmentManifestStore, query: TieredAssessmentManifestQuery) -> [TieredAssessmentManifest] {
        return query.apply(store.list())
    }
}
