import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive statement snapshots by code.
    protocol AdaptiveStatementSnapshotStore {
        func find(_ code: String) -> AdaptiveStatementSnapshot?
        func save(_ item: AdaptiveStatementSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStatementSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStatementSnapshotStore: AdaptiveStatementSnapshotStore {
        var items: [String: AdaptiveStatementSnapshot]
        var order: [String]

        init(items: [String: AdaptiveStatementSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStatementSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStatementSnapshot) {
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

        func list() -> [AdaptiveStatementSnapshot] {
            var out: [AdaptiveStatementSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStatementSnapshotStore() -> any AdaptiveStatementSnapshotStore {
        return MemoryAdaptiveStatementSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStatementSnapshotStore: AdaptiveStatementSnapshotStore {
        var inner: MemoryAdaptiveStatementSnapshotStore
        var cache: TTLCache<AdaptiveStatementSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStatementSnapshotStore, cache: TTLCache<AdaptiveStatementSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStatementSnapshot? {
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

        func save(_ item: AdaptiveStatementSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStatementSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStatementSnapshotStore(_ inner: MemoryAdaptiveStatementSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStatementSnapshotStore {
        return CachedAdaptiveStatementSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive statement snapshots. Empty fields match all.
    final class AdaptiveStatementSnapshotQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStatementSnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AdaptiveStatementSnapshot]) -> [AdaptiveStatementSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStatementSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStatementSnapshots(_ store: any AdaptiveStatementSnapshotStore, query: AdaptiveStatementSnapshotQuery) -> [AdaptiveStatementSnapshot] {
        return query.apply(store.list())
    }
}
