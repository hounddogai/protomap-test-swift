import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered recall assignments by code.
    protocol TieredRecallAssignmentStore {
        func find(_ code: String) -> TieredRecallAssignment?
        func save(_ item: TieredRecallAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRecallAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRecallAssignmentStore: TieredRecallAssignmentStore {
        var items: [String: TieredRecallAssignment]
        var order: [String]

        init(items: [String: TieredRecallAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRecallAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRecallAssignment) {
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

        func list() -> [TieredRecallAssignment] {
            var out: [TieredRecallAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRecallAssignmentStore() -> any TieredRecallAssignmentStore {
        return MemoryTieredRecallAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRecallAssignmentStore: TieredRecallAssignmentStore {
        var inner: MemoryTieredRecallAssignmentStore
        var cache: TTLCache<TieredRecallAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRecallAssignmentStore, cache: TTLCache<TieredRecallAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRecallAssignment? {
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

        func save(_ item: TieredRecallAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRecallAssignment] {
            return inner.list()
        }
    }

    static func newCachedTieredRecallAssignmentStore(_ inner: MemoryTieredRecallAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRecallAssignmentStore {
        return CachedTieredRecallAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered recall assignments. Empty fields match all.
    final class TieredRecallAssignmentQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRecallAssignment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [TieredRecallAssignment]) -> [TieredRecallAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRecallAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRecallAssignments(_ store: any TieredRecallAssignmentStore, query: TieredRecallAssignmentQuery) -> [TieredRecallAssignment] {
        return query.apply(store.list())
    }
}
