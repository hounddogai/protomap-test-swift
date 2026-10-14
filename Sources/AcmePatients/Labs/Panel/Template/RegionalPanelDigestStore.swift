import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional panel digests by code.
    protocol RegionalPanelDigestStore {
        func find(_ code: String) -> RegionalPanelDigest?
        func save(_ item: RegionalPanelDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalPanelDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalPanelDigestStore: RegionalPanelDigestStore {
        var items: [String: RegionalPanelDigest]
        var order: [String]

        init(items: [String: RegionalPanelDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalPanelDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalPanelDigest) {
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

        func list() -> [RegionalPanelDigest] {
            var out: [RegionalPanelDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalPanelDigestStore() -> any RegionalPanelDigestStore {
        return MemoryRegionalPanelDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalPanelDigestStore: RegionalPanelDigestStore {
        var inner: MemoryRegionalPanelDigestStore
        var cache: TTLCache<RegionalPanelDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalPanelDigestStore, cache: TTLCache<RegionalPanelDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalPanelDigest? {
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

        func save(_ item: RegionalPanelDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalPanelDigest] {
            return inner.list()
        }
    }

    static func newCachedRegionalPanelDigestStore(_ inner: MemoryRegionalPanelDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalPanelDigestStore {
        return CachedRegionalPanelDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional panel digests. Empty fields match all.
    final class RegionalPanelDigestQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalPanelDigest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalPanelDigest]) -> [RegionalPanelDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalPanelDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalPanelDigests(_ store: any RegionalPanelDigestStore, query: RegionalPanelDigestQuery) -> [RegionalPanelDigest] {
        return query.apply(store.list())
    }
}
