import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional disclosure snapshots by code.
    protocol RegionalDisclosureSnapshotStore {
        func find(_ code: String) -> RegionalDisclosureSnapshot?
        func save(_ item: RegionalDisclosureSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalDisclosureSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalDisclosureSnapshotStore: RegionalDisclosureSnapshotStore {
        var items: [String: RegionalDisclosureSnapshot]
        var order: [String]

        init(items: [String: RegionalDisclosureSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalDisclosureSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalDisclosureSnapshot) {
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

        func list() -> [RegionalDisclosureSnapshot] {
            var out: [RegionalDisclosureSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalDisclosureSnapshotStore() -> any RegionalDisclosureSnapshotStore {
        return MemoryRegionalDisclosureSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalDisclosureSnapshotStore: RegionalDisclosureSnapshotStore {
        var inner: MemoryRegionalDisclosureSnapshotStore
        var cache: TTLCache<RegionalDisclosureSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalDisclosureSnapshotStore, cache: TTLCache<RegionalDisclosureSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalDisclosureSnapshot? {
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

        func save(_ item: RegionalDisclosureSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalDisclosureSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRegionalDisclosureSnapshotStore(_ inner: MemoryRegionalDisclosureSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalDisclosureSnapshotStore {
        return CachedRegionalDisclosureSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional disclosure snapshots. Empty fields match all.
    final class RegionalDisclosureSnapshotQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalDisclosureSnapshot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalDisclosureSnapshot]) -> [RegionalDisclosureSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalDisclosureSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalDisclosureSnapshots(_ store: any RegionalDisclosureSnapshotStore, query: RegionalDisclosureSnapshotQuery) -> [RegionalDisclosureSnapshot] {
        return query.apply(store.list())
    }
}
