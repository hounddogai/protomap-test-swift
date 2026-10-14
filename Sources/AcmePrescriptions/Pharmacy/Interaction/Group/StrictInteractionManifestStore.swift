import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict interaction manifests by code.
    protocol StrictInteractionManifestStore {
        func find(_ code: String) -> StrictInteractionManifest?
        func save(_ item: StrictInteractionManifest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictInteractionManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictInteractionManifestStore: StrictInteractionManifestStore {
        var items: [String: StrictInteractionManifest]
        var order: [String]

        init(items: [String: StrictInteractionManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictInteractionManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictInteractionManifest) {
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

        func list() -> [StrictInteractionManifest] {
            var out: [StrictInteractionManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictInteractionManifestStore() -> any StrictInteractionManifestStore {
        return MemoryStrictInteractionManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictInteractionManifestStore: StrictInteractionManifestStore {
        var inner: MemoryStrictInteractionManifestStore
        var cache: TTLCache<StrictInteractionManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictInteractionManifestStore, cache: TTLCache<StrictInteractionManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictInteractionManifest? {
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

        func save(_ item: StrictInteractionManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictInteractionManifest] {
            return inner.list()
        }
    }

    static func newCachedStrictInteractionManifestStore(_ inner: MemoryStrictInteractionManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictInteractionManifestStore {
        return CachedStrictInteractionManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict interaction manifests. Empty fields match all.
    final class StrictInteractionManifestQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictInteractionManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictInteractionManifest]) -> [StrictInteractionManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictInteractionManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictInteractionManifests(_ store: any StrictInteractionManifestStore, query: StrictInteractionManifestQuery) -> [StrictInteractionManifest] {
        return query.apply(store.list())
    }
}
