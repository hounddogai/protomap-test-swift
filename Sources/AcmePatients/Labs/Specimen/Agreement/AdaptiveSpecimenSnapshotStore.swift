import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive specimen snapshots by code.
    protocol AdaptiveSpecimenSnapshotStore {
        func find(_ code: String) -> AdaptiveSpecimenSnapshot?
        func save(_ item: AdaptiveSpecimenSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveSpecimenSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveSpecimenSnapshotStore: AdaptiveSpecimenSnapshotStore {
        var items: [String: AdaptiveSpecimenSnapshot]
        var order: [String]

        init(items: [String: AdaptiveSpecimenSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveSpecimenSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveSpecimenSnapshot) {
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

        func list() -> [AdaptiveSpecimenSnapshot] {
            var out: [AdaptiveSpecimenSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveSpecimenSnapshotStore() -> any AdaptiveSpecimenSnapshotStore {
        return MemoryAdaptiveSpecimenSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveSpecimenSnapshotStore: AdaptiveSpecimenSnapshotStore {
        var inner: MemoryAdaptiveSpecimenSnapshotStore
        var cache: TTLCache<AdaptiveSpecimenSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveSpecimenSnapshotStore, cache: TTLCache<AdaptiveSpecimenSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveSpecimenSnapshot? {
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

        func save(_ item: AdaptiveSpecimenSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveSpecimenSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveSpecimenSnapshotStore(_ inner: MemoryAdaptiveSpecimenSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveSpecimenSnapshotStore {
        return CachedAdaptiveSpecimenSnapshotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive specimen snapshots. Empty fields match all.
    final class AdaptiveSpecimenSnapshotQuery {
        var ward: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveSpecimenSnapshot) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveSpecimenSnapshot]) -> [AdaptiveSpecimenSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveSpecimenSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveSpecimenSnapshots(_ store: any AdaptiveSpecimenSnapshotStore, query: AdaptiveSpecimenSnapshotQuery) -> [AdaptiveSpecimenSnapshot] {
        return query.apply(store.list())
    }
}
