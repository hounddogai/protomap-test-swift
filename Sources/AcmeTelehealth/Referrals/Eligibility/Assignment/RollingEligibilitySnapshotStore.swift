import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps rolling eligibility snapshots by code.
    protocol RollingEligibilitySnapshotStore {
        func find(_ code: String) -> RollingEligibilitySnapshot?
        func save(_ item: RollingEligibilitySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [RollingEligibilitySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingEligibilitySnapshotStore: RollingEligibilitySnapshotStore {
        var items: [String: RollingEligibilitySnapshot]
        var order: [String]

        init(items: [String: RollingEligibilitySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingEligibilitySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingEligibilitySnapshot) {
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

        func list() -> [RollingEligibilitySnapshot] {
            var out: [RollingEligibilitySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingEligibilitySnapshotStore() -> any RollingEligibilitySnapshotStore {
        return MemoryRollingEligibilitySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingEligibilitySnapshotStore: RollingEligibilitySnapshotStore {
        var inner: MemoryRollingEligibilitySnapshotStore
        var cache: TTLCache<RollingEligibilitySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingEligibilitySnapshotStore, cache: TTLCache<RollingEligibilitySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingEligibilitySnapshot? {
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

        func save(_ item: RollingEligibilitySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingEligibilitySnapshot] {
            return inner.list()
        }
    }

    static func newCachedRollingEligibilitySnapshotStore(_ inner: MemoryRollingEligibilitySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingEligibilitySnapshotStore {
        return CachedRollingEligibilitySnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling eligibility snapshots. Empty fields match all.
    final class RollingEligibilitySnapshotQuery {
        var source: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minAmount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingEligibilitySnapshot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingEligibilitySnapshot]) -> [RollingEligibilitySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingEligibilitySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingEligibilitySnapshots(_ store: any RollingEligibilitySnapshotStore, query: RollingEligibilitySnapshotQuery) -> [RollingEligibilitySnapshot] {
        return query.apply(store.list())
    }
}
