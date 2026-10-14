import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default cleaning manifests by code.
    protocol DefaultCleaningManifestStore {
        func find(_ code: String) -> DefaultCleaningManifest?
        func save(_ item: DefaultCleaningManifest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCleaningManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCleaningManifestStore: DefaultCleaningManifestStore {
        var items: [String: DefaultCleaningManifest]
        var order: [String]

        init(items: [String: DefaultCleaningManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCleaningManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCleaningManifest) {
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

        func list() -> [DefaultCleaningManifest] {
            var out: [DefaultCleaningManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCleaningManifestStore() -> any DefaultCleaningManifestStore {
        return MemoryDefaultCleaningManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCleaningManifestStore: DefaultCleaningManifestStore {
        var inner: MemoryDefaultCleaningManifestStore
        var cache: TTLCache<DefaultCleaningManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCleaningManifestStore, cache: TTLCache<DefaultCleaningManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCleaningManifest? {
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

        func save(_ item: DefaultCleaningManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCleaningManifest] {
            return inner.list()
        }
    }

    static func newCachedDefaultCleaningManifestStore(_ inner: MemoryDefaultCleaningManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCleaningManifestStore {
        return CachedDefaultCleaningManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default cleaning manifests. Empty fields match all.
    final class DefaultCleaningManifestQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCleaningManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCleaningManifest]) -> [DefaultCleaningManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCleaningManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCleaningManifests(_ store: any DefaultCleaningManifestStore, query: DefaultCleaningManifestQuery) -> [DefaultCleaningManifest] {
        return query.apply(store.list())
    }
}
