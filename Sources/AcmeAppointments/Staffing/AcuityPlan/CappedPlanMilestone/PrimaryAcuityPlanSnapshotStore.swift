import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary acuity plan snapshots by code.
    protocol PrimaryAcuityPlanSnapshotStore {
        func find(_ code: String) -> PrimaryAcuityPlanSnapshot?
        func save(_ item: PrimaryAcuityPlanSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAcuityPlanSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAcuityPlanSnapshotStore: PrimaryAcuityPlanSnapshotStore {
        var items: [String: PrimaryAcuityPlanSnapshot]
        var order: [String]

        init(items: [String: PrimaryAcuityPlanSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAcuityPlanSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAcuityPlanSnapshot) {
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

        func list() -> [PrimaryAcuityPlanSnapshot] {
            var out: [PrimaryAcuityPlanSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAcuityPlanSnapshotStore() -> any PrimaryAcuityPlanSnapshotStore {
        return MemoryPrimaryAcuityPlanSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAcuityPlanSnapshotStore: PrimaryAcuityPlanSnapshotStore {
        var inner: MemoryPrimaryAcuityPlanSnapshotStore
        var cache: TTLCache<PrimaryAcuityPlanSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAcuityPlanSnapshotStore, cache: TTLCache<PrimaryAcuityPlanSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAcuityPlanSnapshot? {
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

        func save(_ item: PrimaryAcuityPlanSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAcuityPlanSnapshot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAcuityPlanSnapshotStore(_ inner: MemoryPrimaryAcuityPlanSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAcuityPlanSnapshotStore {
        return CachedPrimaryAcuityPlanSnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary acuity plan snapshots. Empty fields match all.
    final class PrimaryAcuityPlanSnapshotQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAcuityPlanSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAcuityPlanSnapshot]) -> [PrimaryAcuityPlanSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAcuityPlanSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAcuityPlanSnapshots(_ store: any PrimaryAcuityPlanSnapshotStore, query: PrimaryAcuityPlanSnapshotQuery) -> [PrimaryAcuityPlanSnapshot] {
        return query.apply(store.list())
    }
}
