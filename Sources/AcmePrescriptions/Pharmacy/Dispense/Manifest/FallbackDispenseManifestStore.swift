import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback dispense manifests by code.
    protocol FallbackDispenseManifestStore {
        func find(_ code: String) -> FallbackDispenseManifest?
        func save(_ item: FallbackDispenseManifest)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDispenseManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDispenseManifestStore: FallbackDispenseManifestStore {
        var items: [String: FallbackDispenseManifest]
        var order: [String]

        init(items: [String: FallbackDispenseManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDispenseManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDispenseManifest) {
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

        func list() -> [FallbackDispenseManifest] {
            var out: [FallbackDispenseManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDispenseManifestStore() -> any FallbackDispenseManifestStore {
        return MemoryFallbackDispenseManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDispenseManifestStore: FallbackDispenseManifestStore {
        var inner: MemoryFallbackDispenseManifestStore
        var cache: TTLCache<FallbackDispenseManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDispenseManifestStore, cache: TTLCache<FallbackDispenseManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDispenseManifest? {
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

        func save(_ item: FallbackDispenseManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDispenseManifest] {
            return inner.list()
        }
    }

    static func newCachedFallbackDispenseManifestStore(_ inner: MemoryFallbackDispenseManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDispenseManifestStore {
        return CachedFallbackDispenseManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback dispense manifests. Empty fields match all.
    final class FallbackDispenseManifestQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDispenseManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDispenseManifest]) -> [FallbackDispenseManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDispenseManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDispenseManifests(_ store: any FallbackDispenseManifestStore, query: FallbackDispenseManifestQuery) -> [FallbackDispenseManifest] {
        return query.apply(store.list())
    }
}
