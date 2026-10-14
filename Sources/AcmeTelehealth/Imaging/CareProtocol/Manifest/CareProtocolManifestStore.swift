import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol manifests by code.
    protocol CareProtocolManifestStore {
        func find(_ code: String) -> CareProtocolManifest?
        func save(_ item: CareProtocolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolManifestStore: CareProtocolManifestStore {
        var items: [String: CareProtocolManifest]
        var order: [String]

        init(items: [String: CareProtocolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolManifest) {
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

        func list() -> [CareProtocolManifest] {
            var out: [CareProtocolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolManifestStore() -> any CareProtocolManifestStore {
        return MemoryCareProtocolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolManifestStore: CareProtocolManifestStore {
        var inner: MemoryCareProtocolManifestStore
        var cache: TTLCache<CareProtocolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolManifestStore, cache: TTLCache<CareProtocolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolManifest? {
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

        func save(_ item: CareProtocolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolManifest] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolManifestStore(_ inner: MemoryCareProtocolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolManifestStore {
        return CachedCareProtocolManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol manifests. Empty fields match all.
    final class CareProtocolManifestQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolManifest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [CareProtocolManifest]) -> [CareProtocolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolManifests(_ store: any CareProtocolManifestStore, query: CareProtocolManifestQuery) -> [CareProtocolManifest] {
        return query.apply(store.list())
    }
}
