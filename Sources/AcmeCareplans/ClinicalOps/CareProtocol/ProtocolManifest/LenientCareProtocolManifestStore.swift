import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps lenient care protocol manifests by code.
    protocol LenientCareProtocolManifestStore {
        func find(_ code: String) -> LenientCareProtocolManifest?
        func save(_ item: LenientCareProtocolManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareProtocolManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareProtocolManifestStore: LenientCareProtocolManifestStore {
        var items: [String: LenientCareProtocolManifest]
        var order: [String]

        init(items: [String: LenientCareProtocolManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareProtocolManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareProtocolManifest) {
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

        func list() -> [LenientCareProtocolManifest] {
            var out: [LenientCareProtocolManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareProtocolManifestStore() -> any LenientCareProtocolManifestStore {
        return MemoryLenientCareProtocolManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareProtocolManifestStore: LenientCareProtocolManifestStore {
        var inner: MemoryLenientCareProtocolManifestStore
        var cache: TTLCache<LenientCareProtocolManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareProtocolManifestStore, cache: TTLCache<LenientCareProtocolManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareProtocolManifest? {
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

        func save(_ item: LenientCareProtocolManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareProtocolManifest] {
            return inner.list()
        }
    }

    static func newCachedLenientCareProtocolManifestStore(_ inner: MemoryLenientCareProtocolManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareProtocolManifestStore {
        return CachedLenientCareProtocolManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care protocol manifests. Empty fields match all.
    final class LenientCareProtocolManifestQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareProtocolManifest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCareProtocolManifest]) -> [LenientCareProtocolManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareProtocolManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareProtocolManifests(_ store: any LenientCareProtocolManifestStore, query: LenientCareProtocolManifestQuery) -> [LenientCareProtocolManifest] {
        return query.apply(store.list())
    }
}
