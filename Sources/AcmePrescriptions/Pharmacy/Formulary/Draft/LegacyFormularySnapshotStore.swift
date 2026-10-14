import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy formulary snapshots by code.
    protocol LegacyFormularySnapshotStore {
        func find(_ code: String) -> LegacyFormularySnapshot?
        func save(_ item: LegacyFormularySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyFormularySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyFormularySnapshotStore: LegacyFormularySnapshotStore {
        var items: [String: LegacyFormularySnapshot]
        var order: [String]

        init(items: [String: LegacyFormularySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyFormularySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyFormularySnapshot) {
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

        func list() -> [LegacyFormularySnapshot] {
            var out: [LegacyFormularySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyFormularySnapshotStore() -> any LegacyFormularySnapshotStore {
        return MemoryLegacyFormularySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyFormularySnapshotStore: LegacyFormularySnapshotStore {
        var inner: MemoryLegacyFormularySnapshotStore
        var cache: TTLCache<LegacyFormularySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyFormularySnapshotStore, cache: TTLCache<LegacyFormularySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyFormularySnapshot? {
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

        func save(_ item: LegacyFormularySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyFormularySnapshot] {
            return inner.list()
        }
    }

    static func newCachedLegacyFormularySnapshotStore(_ inner: MemoryLegacyFormularySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyFormularySnapshotStore {
        return CachedLegacyFormularySnapshotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy formulary snapshots. Empty fields match all.
    final class LegacyFormularySnapshotQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyFormularySnapshot) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyFormularySnapshot]) -> [LegacyFormularySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyFormularySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyFormularySnapshots(_ store: any LegacyFormularySnapshotStore, query: LegacyFormularySnapshotQuery) -> [LegacyFormularySnapshot] {
        return query.apply(store.list())
    }
}
