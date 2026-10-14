import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task snapshots by code.
    protocol TaskSnapshotStore {
        func find(_ code: String) -> TaskSnapshot?
        func save(_ item: TaskSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [TaskSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskSnapshotStore: TaskSnapshotStore {
        var items: [String: TaskSnapshot]
        var order: [String]

        init(items: [String: TaskSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskSnapshot) {
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

        func list() -> [TaskSnapshot] {
            var out: [TaskSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskSnapshotStore() -> any TaskSnapshotStore {
        return MemoryTaskSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskSnapshotStore: TaskSnapshotStore {
        var inner: MemoryTaskSnapshotStore
        var cache: TTLCache<TaskSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskSnapshotStore, cache: TTLCache<TaskSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskSnapshot? {
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

        func save(_ item: TaskSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskSnapshot] {
            return inner.list()
        }
    }

    static func newCachedTaskSnapshotStore(_ inner: MemoryTaskSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskSnapshotStore {
        return CachedTaskSnapshotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task snapshots. Empty fields match all.
    final class TaskSnapshotQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskSnapshot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [TaskSnapshot]) -> [TaskSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskSnapshots(_ store: any TaskSnapshotStore, query: TaskSnapshotQuery) -> [TaskSnapshot] {
        return query.apply(store.list())
    }
}
