import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy reference range manifests by code.
    protocol LegacyReferenceRangeManifestStore {
        func find(_ code: String) -> LegacyReferenceRangeManifest?
        func save(_ item: LegacyReferenceRangeManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyReferenceRangeManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyReferenceRangeManifestStore: LegacyReferenceRangeManifestStore {
        var items: [String: LegacyReferenceRangeManifest]
        var order: [String]

        init(items: [String: LegacyReferenceRangeManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyReferenceRangeManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyReferenceRangeManifest) {
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

        func list() -> [LegacyReferenceRangeManifest] {
            var out: [LegacyReferenceRangeManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyReferenceRangeManifestStore() -> any LegacyReferenceRangeManifestStore {
        return MemoryLegacyReferenceRangeManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyReferenceRangeManifestStore: LegacyReferenceRangeManifestStore {
        var inner: MemoryLegacyReferenceRangeManifestStore
        var cache: TTLCache<LegacyReferenceRangeManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyReferenceRangeManifestStore, cache: TTLCache<LegacyReferenceRangeManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyReferenceRangeManifest? {
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

        func save(_ item: LegacyReferenceRangeManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyReferenceRangeManifest] {
            return inner.list()
        }
    }

    static func newCachedLegacyReferenceRangeManifestStore(_ inner: MemoryLegacyReferenceRangeManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyReferenceRangeManifestStore {
        return CachedLegacyReferenceRangeManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy reference range manifests. Empty fields match all.
    final class LegacyReferenceRangeManifestQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyReferenceRangeManifest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [LegacyReferenceRangeManifest]) -> [LegacyReferenceRangeManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyReferenceRangeManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyReferenceRangeManifests(_ store: any LegacyReferenceRangeManifestStore, query: LegacyReferenceRangeManifestQuery) -> [LegacyReferenceRangeManifest] {
        return query.apply(store.list())
    }
}
