import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped formulary snapshots by code.
    protocol CappedFormularySnapshotStore {
        func find(_ code: String) -> CappedFormularySnapshot?
        func save(_ item: CappedFormularySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFormularySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFormularySnapshotStore: CappedFormularySnapshotStore {
        var items: [String: CappedFormularySnapshot]
        var order: [String]

        init(items: [String: CappedFormularySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFormularySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFormularySnapshot) {
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

        func list() -> [CappedFormularySnapshot] {
            var out: [CappedFormularySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFormularySnapshotStore() -> any CappedFormularySnapshotStore {
        return MemoryCappedFormularySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFormularySnapshotStore: CappedFormularySnapshotStore {
        var inner: MemoryCappedFormularySnapshotStore
        var cache: TTLCache<CappedFormularySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFormularySnapshotStore, cache: TTLCache<CappedFormularySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFormularySnapshot? {
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

        func save(_ item: CappedFormularySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFormularySnapshot] {
            return inner.list()
        }
    }

    static func newCachedCappedFormularySnapshotStore(_ inner: MemoryCappedFormularySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFormularySnapshotStore {
        return CachedCappedFormularySnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped formulary snapshots. Empty fields match all.
    final class CappedFormularySnapshotQuery {
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

        func matches(_ item: CappedFormularySnapshot) -> Bool {
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

        func apply(_ items: [CappedFormularySnapshot]) -> [CappedFormularySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFormularySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFormularySnapshots(_ store: any CappedFormularySnapshotStore, query: CappedFormularySnapshotQuery) -> [CappedFormularySnapshot] {
        return query.apply(store.list())
    }
}
