import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance snapshots by code.
    protocol RemittanceSnapshotStore {
        func find(_ code: String) -> RemittanceSnapshot?
        func save(_ item: RemittanceSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceSnapshotStore: RemittanceSnapshotStore {
        var items: [String: RemittanceSnapshot]
        var order: [String]

        init(items: [String: RemittanceSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceSnapshot) {
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

        func list() -> [RemittanceSnapshot] {
            var out: [RemittanceSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceSnapshotStore() -> any RemittanceSnapshotStore {
        return MemoryRemittanceSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceSnapshotStore: RemittanceSnapshotStore {
        var inner: MemoryRemittanceSnapshotStore
        var cache: TTLCache<RemittanceSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceSnapshotStore, cache: TTLCache<RemittanceSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceSnapshot? {
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

        func save(_ item: RemittanceSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceSnapshot] {
            return inner.list()
        }
    }

    static func newCachedRemittanceSnapshotStore(_ inner: MemoryRemittanceSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceSnapshotStore {
        return CachedRemittanceSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance snapshots. Empty fields match all.
    final class RemittanceSnapshotQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceSnapshot) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceSnapshot]) -> [RemittanceSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceSnapshots(_ store: any RemittanceSnapshotStore, query: RemittanceSnapshotQuery) -> [RemittanceSnapshot] {
        return query.apply(store.list())
    }
}
