import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global denial manifests by code.
    protocol GlobalDenialManifestStore {
        func find(_ code: String) -> GlobalDenialManifest?
        func save(_ item: GlobalDenialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDenialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDenialManifestStore: GlobalDenialManifestStore {
        var items: [String: GlobalDenialManifest]
        var order: [String]

        init(items: [String: GlobalDenialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDenialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDenialManifest) {
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

        func list() -> [GlobalDenialManifest] {
            var out: [GlobalDenialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDenialManifestStore() -> any GlobalDenialManifestStore {
        return MemoryGlobalDenialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDenialManifestStore: GlobalDenialManifestStore {
        var inner: MemoryGlobalDenialManifestStore
        var cache: TTLCache<GlobalDenialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDenialManifestStore, cache: TTLCache<GlobalDenialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDenialManifest? {
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

        func save(_ item: GlobalDenialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDenialManifest] {
            return inner.list()
        }
    }

    static func newCachedGlobalDenialManifestStore(_ inner: MemoryGlobalDenialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDenialManifestStore {
        return CachedGlobalDenialManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global denial manifests. Empty fields match all.
    final class GlobalDenialManifestQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDenialManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [GlobalDenialManifest]) -> [GlobalDenialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDenialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDenialManifests(_ store: any GlobalDenialManifestStore, query: GlobalDenialManifestQuery) -> [GlobalDenialManifest] {
        return query.apply(store.list())
    }
}
