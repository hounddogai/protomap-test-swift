import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered eligibility snapshots by code.
    protocol TieredEligibilitySnapshotStore {
        func find(_ code: String) -> TieredEligibilitySnapshot?
        func save(_ item: TieredEligibilitySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [TieredEligibilitySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredEligibilitySnapshotStore: TieredEligibilitySnapshotStore {
        var items: [String: TieredEligibilitySnapshot]
        var order: [String]

        init(items: [String: TieredEligibilitySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredEligibilitySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredEligibilitySnapshot) {
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

        func list() -> [TieredEligibilitySnapshot] {
            var out: [TieredEligibilitySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredEligibilitySnapshotStore() -> any TieredEligibilitySnapshotStore {
        return MemoryTieredEligibilitySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredEligibilitySnapshotStore: TieredEligibilitySnapshotStore {
        var inner: MemoryTieredEligibilitySnapshotStore
        var cache: TTLCache<TieredEligibilitySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredEligibilitySnapshotStore, cache: TTLCache<TieredEligibilitySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredEligibilitySnapshot? {
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

        func save(_ item: TieredEligibilitySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredEligibilitySnapshot] {
            return inner.list()
        }
    }

    static func newCachedTieredEligibilitySnapshotStore(_ inner: MemoryTieredEligibilitySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredEligibilitySnapshotStore {
        return CachedTieredEligibilitySnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered eligibility snapshots. Empty fields match all.
    final class TieredEligibilitySnapshotQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredEligibilitySnapshot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredEligibilitySnapshot]) -> [TieredEligibilitySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredEligibilitySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredEligibilitySnapshots(_ store: any TieredEligibilitySnapshotStore, query: TieredEligibilitySnapshotQuery) -> [TieredEligibilitySnapshot] {
        return query.apply(store.list())
    }
}
