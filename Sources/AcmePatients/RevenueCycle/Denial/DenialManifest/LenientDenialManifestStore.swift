import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient denial manifests by code.
    protocol LenientDenialManifestStore {
        func find(_ code: String) -> LenientDenialManifest?
        func save(_ item: LenientDenialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDenialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDenialManifestStore: LenientDenialManifestStore {
        var items: [String: LenientDenialManifest]
        var order: [String]

        init(items: [String: LenientDenialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDenialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDenialManifest) {
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

        func list() -> [LenientDenialManifest] {
            var out: [LenientDenialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDenialManifestStore() -> any LenientDenialManifestStore {
        return MemoryLenientDenialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDenialManifestStore: LenientDenialManifestStore {
        var inner: MemoryLenientDenialManifestStore
        var cache: TTLCache<LenientDenialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDenialManifestStore, cache: TTLCache<LenientDenialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDenialManifest? {
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

        func save(_ item: LenientDenialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDenialManifest] {
            return inner.list()
        }
    }

    static func newCachedLenientDenialManifestStore(_ inner: MemoryLenientDenialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDenialManifestStore {
        return CachedLenientDenialManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient denial manifests. Empty fields match all.
    final class LenientDenialManifestQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDenialManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDenialManifest]) -> [LenientDenialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDenialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDenialManifests(_ store: any LenientDenialManifestStore, query: LenientDenialManifestQuery) -> [LenientDenialManifest] {
        return query.apply(store.list())
    }
}
