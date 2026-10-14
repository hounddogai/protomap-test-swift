import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning manifests by code.
    protocol CleaningManifestStore {
        func find(_ code: String) -> CleaningManifest?
        func save(_ item: CleaningManifest)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningManifestStore: CleaningManifestStore {
        var items: [String: CleaningManifest]
        var order: [String]

        init(items: [String: CleaningManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningManifest) {
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

        func list() -> [CleaningManifest] {
            var out: [CleaningManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningManifestStore() -> any CleaningManifestStore {
        return MemoryCleaningManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningManifestStore: CleaningManifestStore {
        var inner: MemoryCleaningManifestStore
        var cache: TTLCache<CleaningManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningManifestStore, cache: TTLCache<CleaningManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningManifest? {
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

        func save(_ item: CleaningManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningManifest] {
            return inner.list()
        }
    }

    static func newCachedCleaningManifestStore(_ inner: MemoryCleaningManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningManifestStore {
        return CachedCleaningManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning manifests. Empty fields match all.
    final class CleaningManifestQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningManifest]) -> [CleaningManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningManifests(_ store: any CleaningManifestStore, query: CleaningManifestQuery) -> [CleaningManifest] {
        return query.apply(store.list())
    }
}
