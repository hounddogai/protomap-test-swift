import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual remittance snapshots by code.
    protocol ManualRemittanceSnapshotStore {
        func find(_ code: String) -> ManualRemittanceSnapshot?
        func save(_ item: ManualRemittanceSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRemittanceSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRemittanceSnapshotStore: ManualRemittanceSnapshotStore {
        var items: [String: ManualRemittanceSnapshot]
        var order: [String]

        init(items: [String: ManualRemittanceSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRemittanceSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRemittanceSnapshot) {
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

        func list() -> [ManualRemittanceSnapshot] {
            var out: [ManualRemittanceSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRemittanceSnapshotStore() -> any ManualRemittanceSnapshotStore {
        return MemoryManualRemittanceSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRemittanceSnapshotStore: ManualRemittanceSnapshotStore {
        var inner: MemoryManualRemittanceSnapshotStore
        var cache: TTLCache<ManualRemittanceSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRemittanceSnapshotStore, cache: TTLCache<ManualRemittanceSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRemittanceSnapshot? {
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

        func save(_ item: ManualRemittanceSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRemittanceSnapshot] {
            return inner.list()
        }
    }

    static func newCachedManualRemittanceSnapshotStore(_ inner: MemoryManualRemittanceSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRemittanceSnapshotStore {
        return CachedManualRemittanceSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual remittance snapshots. Empty fields match all.
    final class ManualRemittanceSnapshotQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRemittanceSnapshot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRemittanceSnapshot]) -> [ManualRemittanceSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRemittanceSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRemittanceSnapshots(_ store: any ManualRemittanceSnapshotStore, query: ManualRemittanceSnapshotQuery) -> [ManualRemittanceSnapshot] {
        return query.apply(store.list())
    }
}
