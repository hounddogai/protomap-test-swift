import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional alert snapshots by code.
    protocol RegionalAlertSnapshotStore {
        func find(_ code: String) -> RegionalAlertSnapshot?
        func save(_ item: RegionalAlertSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAlertSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAlertSnapshotStore: RegionalAlertSnapshotStore {
        var items: [String: RegionalAlertSnapshot]
        var order: [String]

        init(items: [String: RegionalAlertSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAlertSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAlertSnapshot) {
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

        func list() -> [RegionalAlertSnapshot] {
            var out: [RegionalAlertSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAlertSnapshotStore() -> any RegionalAlertSnapshotStore {
        return MemoryRegionalAlertSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAlertSnapshotStore: RegionalAlertSnapshotStore {
        var inner: MemoryRegionalAlertSnapshotStore
        var cache: TTLCache<RegionalAlertSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAlertSnapshotStore, cache: TTLCache<RegionalAlertSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAlertSnapshot? {
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

        func save(_ item: RegionalAlertSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAlertSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRegionalAlertSnapshotStore(_ inner: MemoryRegionalAlertSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAlertSnapshotStore {
        return CachedRegionalAlertSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional alert snapshots. Empty fields match all.
    final class RegionalAlertSnapshotQuery {
        var country: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCost: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAlertSnapshot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [RegionalAlertSnapshot]) -> [RegionalAlertSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAlertSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAlertSnapshots(_ store: any RegionalAlertSnapshotStore, query: RegionalAlertSnapshotQuery) -> [RegionalAlertSnapshot] {
        return query.apply(store.list())
    }
}
