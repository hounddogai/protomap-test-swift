import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation manifests by code.
    protocol RevocationManifestStore {
        func find(_ code: String) -> RevocationManifest?
        func save(_ item: RevocationManifest)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationManifestStore: RevocationManifestStore {
        var items: [String: RevocationManifest]
        var order: [String]

        init(items: [String: RevocationManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationManifest) {
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

        func list() -> [RevocationManifest] {
            var out: [RevocationManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationManifestStore() -> any RevocationManifestStore {
        return MemoryRevocationManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationManifestStore: RevocationManifestStore {
        var inner: MemoryRevocationManifestStore
        var cache: TTLCache<RevocationManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationManifestStore, cache: TTLCache<RevocationManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationManifest? {
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

        func save(_ item: RevocationManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationManifest] {
            return inner.list()
        }
    }

    static func newCachedRevocationManifestStore(_ inner: MemoryRevocationManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationManifestStore {
        return CachedRevocationManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation manifests. Empty fields match all.
    final class RevocationManifestQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationManifest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationManifest]) -> [RevocationManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationManifests(_ store: any RevocationManifestStore, query: RevocationManifestQuery) -> [RevocationManifest] {
        return query.apply(store.list())
    }
}
