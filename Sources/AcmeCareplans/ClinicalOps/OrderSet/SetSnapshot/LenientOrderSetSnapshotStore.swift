import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps lenient order set snapshots by code.
    protocol LenientOrderSetSnapshotStore {
        func find(_ code: String) -> LenientOrderSetSnapshot?
        func save(_ item: LenientOrderSetSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOrderSetSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOrderSetSnapshotStore: LenientOrderSetSnapshotStore {
        var items: [String: LenientOrderSetSnapshot]
        var order: [String]

        init(items: [String: LenientOrderSetSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOrderSetSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOrderSetSnapshot) {
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

        func list() -> [LenientOrderSetSnapshot] {
            var out: [LenientOrderSetSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOrderSetSnapshotStore() -> any LenientOrderSetSnapshotStore {
        return MemoryLenientOrderSetSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOrderSetSnapshotStore: LenientOrderSetSnapshotStore {
        var inner: MemoryLenientOrderSetSnapshotStore
        var cache: TTLCache<LenientOrderSetSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOrderSetSnapshotStore, cache: TTLCache<LenientOrderSetSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOrderSetSnapshot? {
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

        func save(_ item: LenientOrderSetSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOrderSetSnapshot] {
            return inner.list()
        }
    }

    static func newCachedLenientOrderSetSnapshotStore(_ inner: MemoryLenientOrderSetSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOrderSetSnapshotStore {
        return CachedLenientOrderSetSnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient order set snapshots. Empty fields match all.
    final class LenientOrderSetSnapshotQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOrderSetSnapshot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOrderSetSnapshot]) -> [LenientOrderSetSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOrderSetSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOrderSetSnapshots(_ store: any LenientOrderSetSnapshotStore, query: LenientOrderSetSnapshotQuery) -> [LenientOrderSetSnapshot] {
        return query.apply(store.list())
    }
}
