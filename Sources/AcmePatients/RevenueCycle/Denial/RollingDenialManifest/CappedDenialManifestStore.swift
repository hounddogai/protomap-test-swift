import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped denial manifests by code.
    protocol CappedDenialManifestStore {
        func find(_ code: String) -> CappedDenialManifest?
        func save(_ item: CappedDenialManifest)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDenialManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDenialManifestStore: CappedDenialManifestStore {
        var items: [String: CappedDenialManifest]
        var order: [String]

        init(items: [String: CappedDenialManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDenialManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDenialManifest) {
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

        func list() -> [CappedDenialManifest] {
            var out: [CappedDenialManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDenialManifestStore() -> any CappedDenialManifestStore {
        return MemoryCappedDenialManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDenialManifestStore: CappedDenialManifestStore {
        var inner: MemoryCappedDenialManifestStore
        var cache: TTLCache<CappedDenialManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDenialManifestStore, cache: TTLCache<CappedDenialManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDenialManifest? {
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

        func save(_ item: CappedDenialManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDenialManifest] {
            return inner.list()
        }
    }

    static func newCachedCappedDenialManifestStore(_ inner: MemoryCappedDenialManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDenialManifestStore {
        return CachedCappedDenialManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped denial manifests. Empty fields match all.
    final class CappedDenialManifestQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDenialManifest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDenialManifest]) -> [CappedDenialManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDenialManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDenialManifests(_ store: any CappedDenialManifestStore, query: CappedDenialManifestQuery) -> [CappedDenialManifest] {
        return query.apply(store.list())
    }
}
