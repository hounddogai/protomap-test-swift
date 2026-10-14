import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending credential manifests by code.
    protocol PendingCredentialManifestStore {
        func find(_ code: String) -> PendingCredentialManifest?
        func save(_ item: PendingCredentialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCredentialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCredentialManifestStore: PendingCredentialManifestStore {
        var items: [String: PendingCredentialManifest]
        var order: [String]

        init(items: [String: PendingCredentialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCredentialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCredentialManifest) {
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

        func list() -> [PendingCredentialManifest] {
            var out: [PendingCredentialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCredentialManifestStore() -> any PendingCredentialManifestStore {
        return MemoryPendingCredentialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCredentialManifestStore: PendingCredentialManifestStore {
        var inner: MemoryPendingCredentialManifestStore
        var cache: TTLCache<PendingCredentialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCredentialManifestStore, cache: TTLCache<PendingCredentialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCredentialManifest? {
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

        func save(_ item: PendingCredentialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCredentialManifest] {
            return inner.list()
        }
    }

    static func newCachedPendingCredentialManifestStore(_ inner: MemoryPendingCredentialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCredentialManifestStore {
        return CachedPendingCredentialManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending credential manifests. Empty fields match all.
    final class PendingCredentialManifestQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCredentialManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingCredentialManifest]) -> [PendingCredentialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCredentialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCredentialManifests(_ store: any PendingCredentialManifestStore, query: PendingCredentialManifestQuery) -> [PendingCredentialManifest] {
        return query.apply(store.list())
    }
}
