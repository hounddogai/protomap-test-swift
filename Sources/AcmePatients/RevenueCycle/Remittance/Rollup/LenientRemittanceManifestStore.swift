import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient remittance manifests by code.
    protocol LenientRemittanceManifestStore {
        func find(_ code: String) -> LenientRemittanceManifest?
        func save(_ item: LenientRemittanceManifest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRemittanceManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRemittanceManifestStore: LenientRemittanceManifestStore {
        var items: [String: LenientRemittanceManifest]
        var order: [String]

        init(items: [String: LenientRemittanceManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRemittanceManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRemittanceManifest) {
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

        func list() -> [LenientRemittanceManifest] {
            var out: [LenientRemittanceManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRemittanceManifestStore() -> any LenientRemittanceManifestStore {
        return MemoryLenientRemittanceManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRemittanceManifestStore: LenientRemittanceManifestStore {
        var inner: MemoryLenientRemittanceManifestStore
        var cache: TTLCache<LenientRemittanceManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRemittanceManifestStore, cache: TTLCache<LenientRemittanceManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRemittanceManifest? {
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

        func save(_ item: LenientRemittanceManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRemittanceManifest] {
            return inner.list()
        }
    }

    static func newCachedLenientRemittanceManifestStore(_ inner: MemoryLenientRemittanceManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRemittanceManifestStore {
        return CachedLenientRemittanceManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient remittance manifests. Empty fields match all.
    final class LenientRemittanceManifestQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRemittanceManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRemittanceManifest]) -> [LenientRemittanceManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRemittanceManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRemittanceManifests(_ store: any LenientRemittanceManifestStore, query: LenientRemittanceManifestQuery) -> [LenientRemittanceManifest] {
        return query.apply(store.list())
    }
}
