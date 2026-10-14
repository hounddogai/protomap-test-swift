import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped statement snapshots by code.
    protocol CappedStatementSnapshotStore {
        func find(_ code: String) -> CappedStatementSnapshot?
        func save(_ item: CappedStatementSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedStatementSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedStatementSnapshotStore: CappedStatementSnapshotStore {
        var items: [String: CappedStatementSnapshot]
        var order: [String]

        init(items: [String: CappedStatementSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedStatementSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedStatementSnapshot) {
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

        func list() -> [CappedStatementSnapshot] {
            var out: [CappedStatementSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedStatementSnapshotStore() -> any CappedStatementSnapshotStore {
        return MemoryCappedStatementSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedStatementSnapshotStore: CappedStatementSnapshotStore {
        var inner: MemoryCappedStatementSnapshotStore
        var cache: TTLCache<CappedStatementSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedStatementSnapshotStore, cache: TTLCache<CappedStatementSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedStatementSnapshot? {
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

        func save(_ item: CappedStatementSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedStatementSnapshot] {
            return inner.list()
        }
    }

    static func newCachedCappedStatementSnapshotStore(_ inner: MemoryCappedStatementSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedStatementSnapshotStore {
        return CachedCappedStatementSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped statement snapshots. Empty fields match all.
    final class CappedStatementSnapshotQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedStatementSnapshot) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedStatementSnapshot]) -> [CappedStatementSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedStatementSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedStatementSnapshots(_ store: any CappedStatementSnapshotStore, query: CappedStatementSnapshotQuery) -> [CappedStatementSnapshot] {
        return query.apply(store.list())
    }
}
